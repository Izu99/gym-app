const Member = require('../models/Member');
const Payment = require('../models/Payment');
const Tier = require('../models/Tier');
const Subscription = require('../models/Subscription');
const mongoose = require('mongoose');

async function upsertCurrentSubscription(member, ownerId, { mode = 'immediate' } = {}) {
  const tier = await Tier.findOne({ _id: member.tier, owner: ownerId });
  if (!tier) throw new Error('Assigned package not found');

  let subscription = null;
  if (member.currentSubscription) {
    subscription = await Subscription.findOne({
      _id: member.currentSubscription,
      owner: ownerId,
    });
  }

  if (!subscription) {
    subscription = new Subscription({
      owner: ownerId,
      member: member._id,
      tier: tier._id,
      packageName: tier.name,
      billingAmount: member.monthlyFee,
      billingCycle: tier.billingCycle || 'monthly',
      startDate: member.memberSince || new Date(),
      nextBillingDate: member.nextPaymentDate,
      status: member.isActive ? 'active' : 'cancelled',
      changeMode: mode,
    });
  } else {
    subscription.tier = tier._id;
    subscription.packageName = tier.name;
    subscription.billingAmount = member.monthlyFee;
    subscription.billingCycle = tier.billingCycle || subscription.billingCycle;
    subscription.nextBillingDate = member.nextPaymentDate;
    subscription.status = member.isActive ? 'active' : subscription.status;
    subscription.changeMode = mode;
  }

  await subscription.save();
  member.currentSubscription = subscription._id;
  return subscription;
}

function cycleMonths(cycle) {
  if (cycle === 'yearly') return 12;
  if (cycle === 'half_yearly') return 6;
  if (cycle === 'quarterly') return 3;
  return 1;
}

function nextBillingFrom(startDate, cycle) {
  const next = new Date(startDate);
  next.setMonth(next.getMonth() + cycleMonths(cycle));
  return next;
}

// @desc    Get all members
// @route   GET /api/members
exports.getMembers = async (req, res) => {
  try {
    const { status, tier, page = 1, limit = 20, search } = req.query;
    const filter = { owner: req.user.id, isActive: true };
    
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
    const tier = await Tier.findOne({ _id: req.body.tier, owner: req.user.id });
    if (!tier) return res.status(404).json({ error: 'Package not found' });

    const memberSince = req.body.memberSince ? new Date(req.body.memberSince) : new Date();
    const member = await Member.create({
      ...req.body,
      owner: req.user.id,
      status: req.body.status ?? 'active',
      memberSince,
      nextPaymentDate:
        req.body.nextPaymentDate != null
            ? new Date(req.body.nextPaymentDate)
            : nextBillingFrom(memberSince, tier.billingCycle || 'monthly'),
    });
    await upsertCurrentSubscription(member, req.user.id);
    await member.save();
    res.status(201).json(member);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Update member
// @route   PATCH /api/members/:id
exports.updateMember = async (req, res) => {
  try {
    const member = await Member.findOne({
      _id: req.params.id,
      owner: req.user.id,
    });
    if (!member) return res.status(404).json({ error: 'Member not found' });

    let tier = null;
    if (req.body.tier != null) {
      tier = await Tier.findOne({ _id: req.body.tier, owner: req.user.id });
      if (!tier) return res.status(404).json({ error: 'Package not found' });
    }

    Object.assign(member, req.body);
    if (tier && req.body.nextPaymentDate == null) {
      member.nextPaymentDate = nextBillingFrom(
        member.memberSince || new Date(),
        tier.billingCycle || 'monthly'
      );
    }
    await upsertCurrentSubscription(member, req.user.id, {
      mode: req.body.changeMode == 'next_cycle' ? 'next_cycle' : 'immediate',
    });
    await member.save();
    res.json(member);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Delete member (Soft Delete)
// @route   DELETE /api/members/:id
exports.deleteMember = async (req, res) => {
  try {
    const member = await Member.findOneAndUpdate(
      { _id: req.params.id, owner: req.user.id },
      {
        isActive: false,
        status: 'cancelled',
        deactivatedAt: new Date(),
        deactivationReason: req.body?.reason || 'manual_deactivation',
      },
      { new: true }
    );
    if (!member) return res.status(404).json({ error: 'Member not found' });

    if (member.currentSubscription) {
      await Subscription.findOneAndUpdate(
        { _id: member.currentSubscription, owner: req.user.id },
        { status: 'cancelled', endedAt: new Date() }
      );
    }

    res.json({ message: 'Member deactivated', member });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
