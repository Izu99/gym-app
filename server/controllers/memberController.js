const Member = require('../models/Member');
const Payment = require('../models/Payment');
const mongoose = require('mongoose');

// @desc    Get all members
// @route   GET /api/members
exports.getMembers = async (req, res) => {
  try {
    const { status, tier, page = 1, limit = 20, search } = req.query;
    const filter = { owner: req.user.id };
    
    // We handle 'overdue' filter specifically since it depends on Payment data
    if (status && status !== 'overdue') filter.paymentStatus = status;
    
    if (tier) filter.tier = tier;
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [members, total] = await Promise.all([
      Member.find(filter).populate('tier').sort({ createdAt: -1 }).skip(skip).limit(Number(limit)),
      Member.countDocuments(filter),
    ]);

    // Dynamically check for overdue payments to ensure paymentStatus is accurate
    const memberIds = members.map(m => m._id);
    const now = new Date();
    const overdueMemberIds = await Payment.distinct('member', {
      owner: new mongoose.Types.ObjectId(req.user.id),
      member: { $in: memberIds },
      status: { $ne: 'paid' },
      dueDate: { $lte: now }
    });

    const overdueSet = new Set(overdueMemberIds.map(id => id.toString()));

    let membersWithDynamicStatus = members.map(m => {
      const member = m.toObject();
      if (overdueSet.has(member._id.toString())) {
        member.paymentStatus = 'overdue';
      }
      return member;
    });

    // If filtering by overdue, we need to filter out members who are not actually overdue
    if (status === 'overdue') {
      membersWithDynamicStatus = membersWithDynamicStatus.filter(m => m.paymentStatus === 'overdue');
    }

    res.json({ 
      members: membersWithDynamicStatus, 
      total, 
      page: Number(page), 
      pages: Math.ceil(total / Number(limit)) 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Get single member
// @route   GET /api/members/:id
exports.getMemberById = async (req, res) => {
  try {
    const member = await Member.findOne({ _id: req.params.id, owner: req.user.id }).populate('tier');
    if (!member) return res.status(404).json({ error: 'Member not found' });
    res.json(member);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Create member
// @route   POST /api/members
exports.createMember = async (req, res) => {
  try {
    const member = await Member.create({ ...req.body, owner: req.user.id });
    res.status(201).json(member);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Update member
// @route   PATCH /api/members/:id
exports.updateMember = async (req, res) => {
  try {
    const member = await Member.findOneAndUpdate(
      { _id: req.params.id, owner: req.user.id },
      req.body,
      { new: true, runValidators: true }
    );
    if (!member) return res.status(404).json({ error: 'Member not found' });
    res.json(member);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Delete member
// @route   DELETE /api/members/:id
exports.deleteMember = async (req, res) => {
  try {
    const member = await Member.findOneAndDelete({ _id: req.params.id, owner: req.user.id });
    if (!member) return res.status(404).json({ error: 'Member not found' });
    res.json({ message: 'Member deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
