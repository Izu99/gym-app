const mongoose = require('mongoose');
const Attendance = require('../models/Attendance');
const Member = require('../models/Member');

// @desc    Get attendance records (merged with members)
// @route   GET /api/attendance
exports.getAttendance = async (req, res) => {
  try {
    const { date, session, page = 1, limit = 20 } = req.query;
    const filter = {};
    const queryDate = date ? new Date(date) : new Date();
    queryDate.setHours(0, 0, 0, 0);

    const start = new Date(queryDate);
    const end = new Date(queryDate);
    end.setHours(23, 59, 59, 999);
    filter.date = { $gte: start, $lte: end };
    if (session && session !== 'ALL') filter.session = session;

    // Get members first to ensure everyone is listed
    const membersTotal = await Member.countDocuments({ owner: req.user.id, isActive: true });
    const skip = (Number(page) - 1) * Number(limit);
    const members = await Member.find({ owner: req.user.id, isActive: true })
      .sort({ name: 1 })
      .skip(skip)
      .limit(Number(limit));

    const memberIds = members.map(m => m._id);
    
    // Find attendance records for these members on this date
    const records = await Attendance.find({
      owner: req.user.id,
      member: { $in: memberIds },
      date: { $gte: start, $lte: end }
    });

    // Map records to members
    const attendanceMap = {};
    records.forEach(r => {
      attendanceMap[r.member.toString()] = r;
    });

    const mergedRecords = members.map(m => {
      const att = attendanceMap[m._id.toString()];
      return {
        _id: att ? att._id : `temp-${m._id}`,
        member: m,
        status: att ? att.status : 'absent',
        session: att ? att.session : session === 'ALL' ? 'Morning' : session,
        checkinTime: att ? att.checkinTime : null,
        date: queryDate
      };
    });

    res.json({
      records: mergedRecords,
      total: membersTotal,
      page: Number(page),
      pages: Math.ceil(membersTotal / Number(limit))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Get attendance calendar for a member
// @route   GET /api/attendance/member-calendar
exports.getMemberAttendanceCalendar = async (req, res) => {
  try {
    const { memberId, month } = req.query;
    if (!memberId) {
      return res.status(400).json({ error: 'memberId is required' });
    }

    const member = await Member.findOne({
      _id: memberId,
      owner: req.user.id,
    }).select('name initials');
    if (!member) return res.status(404).json({ error: 'Member not found' });

    const baseMonth = month ? new Date(`${month}-01`) : new Date();
    if (Number.isNaN(baseMonth.getTime())) {
      return res.status(400).json({ error: 'month must be in YYYY-MM format' });
    }

    const start = new Date(baseMonth.getFullYear(), baseMonth.getMonth(), 1);
    const end = new Date(baseMonth.getFullYear(), baseMonth.getMonth() + 1, 0);
    end.setHours(23, 59, 59, 999);

    const records = await Attendance.find({
      owner: req.user.id,
      member: memberId,
      date: { $gte: start, $lte: end },
    }).sort({ date: 1 });

    res.json({
      member: {
        id: member._id,
        name: member.name,
        initials: member.initials,
      },
      month: `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}`,
      records: records.map((record) => ({
        _id: record._id,
        date: record.date,
        status: record.status,
        session: record.session,
        checkinTime: record.checkinTime,
        checkoutTime: record.checkoutTime,
      })),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Mark attendance
// @route   POST /api/attendance
exports.markAttendance = async (req, res) => {
  try {
    const { memberId, date, status, session } = req.body;
    const day = new Date(date || Date.now());
    day.setHours(0, 0, 0, 0);

    const record = await Attendance.findOneAndUpdate(
      { member: memberId, date: day, owner: req.user.id },
      {
        status,
        session,
        checkinTime: status === 'present' ? new Date() : undefined,
        owner: req.user.id,
      },
      { upsert: true, new: true, runValidators: true }
    ).populate('member', 'name initials tier');

    res.json(record);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Get attendance statistics
// @route   GET /api/attendance/stats
exports.getAttendanceStats = async (req, res) => {
  try {
    const days = Number(req.query.days) || 7;
    const since = new Date();
    since.setDate(since.getDate() - days);

    const stats = await Attendance.aggregate([
      { $match: { owner: new mongoose.Types.ObjectId(req.user.id), date: { $gte: since }, status: 'present' } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
