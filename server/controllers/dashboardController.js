const mongoose = require('mongoose');
const Member = require('../models/Member');
const Attendance = require('../models/Attendance');
const Payment = require('../models/Payment');

// @desc    Get dashboard statistics
// @route   GET /api/dashboard/stats
exports.getDashboardStats = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const now = new Date();
    const [
      totalMembers,
      activeMembers,
      overdueMembers,
      todayAttendance,
      yesterdayAttendance,
      paymentSummary,
      newThisMonth,
    ] = await Promise.all([
      Member.countDocuments({ owner: req.user.id }),
      Member.countDocuments({ owner: req.user.id, isActive: true }),
      // Update overdue count based on payment records since Member.paymentStatus might be stale
      // We consider any payment due on or before today as overdue if unpaid
      Payment.distinct('member', {
        owner: new mongoose.Types.ObjectId(req.user.id),
        status: { $ne: 'paid' },
        dueDate: { $lte: now },
      }).then((members) => members.length),
      Attendance.countDocuments({ owner: req.user.id, date: { $gte: today, $lte: todayEnd }, status: 'present' }),
      Attendance.countDocuments({
        owner: req.user.id,
        date: { $gte: yesterday, $lt: today },
        status: 'present',
      }),
      Payment.aggregate([
        { $match: { owner: new mongoose.Types.ObjectId(req.user.id) } },
        {
          $group: {
            _id: null,
            monthlyRevenue: {
              $sum: { $cond: [{ $eq: ['$status', 'paid'] }, '$amount', 0] },
            },
            overdueCount: {
              $sum: {
                $cond: [
                  {
                    $and: [{ $ne: ['$status', 'paid'] }, { $lte: ['$dueDate', now] }],
                  },
                  1,
                  0,
                ],
              },
            },
          },
        },
      ]),
      Member.countDocuments({
        owner: req.user.id,
        createdAt: {
          $gte: new Date(today.getFullYear(), today.getMonth(), 1),
        },
      }),
    ]);

    const revenue = paymentSummary[0] || { monthlyRevenue: 0, overdueCount: 0 };
    const attendanceDelta =
      yesterdayAttendance > 0
        ? (((todayAttendance - yesterdayAttendance) / yesterdayAttendance) * 100).toFixed(1)
        : 0;

    res.json({
      totalMembers,
      activeMembers,
      overdueMembers,
      newThisMonth,
      dailyAttendance: todayAttendance,
      attendanceDelta: Number(attendanceDelta),
      monthlyRevenue: revenue.monthlyRevenue,
      overduePayments: revenue.overdueCount,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Get member tier breakdown
// @route   GET /api/dashboard/tier-breakdown
exports.getTierBreakdown = async (req, res) => {
  try {
    const breakdown = await Member.aggregate([
      { $match: { owner: new mongoose.Types.ObjectId(req.user.id) } },
      { $group: { _id: '$tier', count: { $sum: 1 } } },
      {
        $lookup: {
          from: 'tiers',
          localField: '_id',
          foreignField: '_id',
          as: 'tierInfo',
        },
      },
      { $unwind: { path: '$tierInfo', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          _id: 1,
          count: 1,
          tier: { $ifNull: ['$tierInfo.name', 'Unknown Package'] },
        },
      },
      { $sort: { count: -1 } },
    ]);
    res.json(breakdown);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
