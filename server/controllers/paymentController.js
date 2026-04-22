const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const Member = require('../models/Member');
const Tier = require('../models/Tier');
const Subscription = require('../models/Subscription');

function cycleMonths(cycle) {
  if (cycle === 'yearly') return 12;
  if (cycle === 'half_yearly') return 6;
  if (cycle === 'quarterly') return 3;
  return 1;
}

function buildInvoiceNumber() {
  const now = new Date();
  const stamp = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}`;
  const suffix = `${now.getHours()}${now.getMinutes()}${now.getSeconds()}${String(now.getMilliseconds()).padStart(3, '0')}`;
  return `INV-${stamp}-${suffix}`;
}

// @desc    Get payments
// @route   GET /api/payments
exports.getPayments = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const filter = { owner: req.user.id };
    if (status) filter.status = status;

    const skip = (Number(page) - 1) * Number(limit);
    const [payments, total] = await Promise.all([
      Payment.find(filter)
        .populate('member', 'name initials phone email tier')
        .sort({ dueDate: -1 })
        .skip(skip)
        .limit(Number(limit)),
      Payment.countDocuments(filter),
    ]);

    const now = new Date();
    const paymentsWithStatus = payments.map((p) => {
      const payment = p.toObject();
      if (payment.status !== 'paid' && new Date(payment.dueDate) <= now) {
        payment.status = 'overdue';
      }
      return payment;
    });

    res.json({
      payments: paymentsWithStatus,
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Create payment
// @route   POST /api/payments
exports.createPayment = async (req, res) => {
  try {
    const { member: memberId, tierId, amount, dueDate, notes } = req.body;

    const member = await Member.findOne({
      _id: memberId,
      owner: req.user.id,
      isActive: true,
    }).populate('tier');
    if (!member) {
      return res.status(404).json({ error: 'Active member not found' });
    }

    const existingUnpaid = await Payment.findOne({
      owner: req.user.id,
      member: memberId,
      status: { $in: ['pending', 'overdue'] },
    });
    if (existingUnpaid) {
      return res.status(400).json({
        error: 'This member already has an unpaid payment record',
      });
    }

    let selectedTier = member.tier;
    if (tierId) {
      selectedTier = await Tier.findOne({
        _id: tierId,
        owner: req.user.id,
        isArchived: { $ne: true },
      });
      if (!selectedTier) {
        return res.status(404).json({ error: 'Selected package not found' });
      }
    }

    let subscription = null;
    if (member.currentSubscription) {
      subscription = await Subscription.findOne({
        _id: member.currentSubscription,
        owner: req.user.id,
      });
    }

    const due = dueDate ? new Date(dueDate) : new Date();
    const billingPeriodStart = subscription?.nextBillingDate
      ? new Date(subscription.nextBillingDate)
      : new Date(member.nextPaymentDate || new Date());
    const billingPeriodEnd = new Date(billingPeriodStart);
    billingPeriodEnd.setMonth(
      billingPeriodEnd.getMonth() + cycleMonths(selectedTier.billingCycle || 'monthly')
    );

    const numericAmount = Number(amount);
    if (!Number.isFinite(numericAmount) || numericAmount < 0) {
      return res.status(400).json({ error: 'Amount must be a valid non-negative number' });
    }

    if (tierId && String(selectedTier._id) !== String(member.tier?._id ?? member.tier)) {
      member.tier = selectedTier._id;
      member.monthlyFee = selectedTier.monthlyFee;
    } else if (tierId) {
      member.monthlyFee = selectedTier.monthlyFee;
    }

    member.paymentStatus = 'pending';
    member.nextPaymentDate = due;
    await member.save();

    if (!subscription) {
      subscription = await Subscription.create({
        owner: req.user.id,
        member: member._id,
        tier: selectedTier._id,
        packageName: selectedTier.name,
        billingAmount: numericAmount,
        billingCycle: selectedTier.billingCycle || 'monthly',
        startDate: member.memberSince || new Date(),
        nextBillingDate: due,
        status: member.isActive ? 'active' : 'cancelled',
      });
      member.currentSubscription = subscription._id;
      await member.save();
    } else {
      subscription.tier = selectedTier._id;
      subscription.packageName = selectedTier.name;
      subscription.billingAmount = numericAmount;
      subscription.billingCycle = selectedTier.billingCycle || subscription.billingCycle;
      subscription.nextBillingDate = due;
      subscription.status = member.isActive ? 'active' : subscription.status;
      await subscription.save();
    }

    const payment = await Payment.create({
      owner: req.user.id,
      member: member._id,
      subscription: subscription._id,
      invoiceNumber: buildInvoiceNumber(),
      plan: selectedTier?.name ?? req.body.plan ?? member.tierLabel ?? 'GENERAL',
      amount: numericAmount,
      paidAmount: 0,
      discountAmount: Number(req.body.discountAmount ?? 0) || 0,
      balanceAmount: numericAmount,
      paymentMethod: req.body.paymentMethod ?? 'manual',
      billingPeriodStart,
      billingPeriodEnd,
      dueDate: due,
      status: 'pending',
      notes,
    });
    const populatedPayment = await Payment.findById(payment._id).populate(
      'member',
      'name initials phone email tier'
    );
    res.status(201).json(populatedPayment);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Mark payment as paid
// @route   PATCH /api/payments/:id/mark-paid
exports.markPaid = async (req, res) => {
  try {
    const existing = await Payment.findOne({ _id: req.params.id, owner: req.user.id });
    if (!existing) return res.status(404).json({ error: 'Payment not found' });

    const payment = await Payment.findOneAndUpdate(
      { _id: req.params.id, owner: req.user.id },
      {
        status: 'paid',
        paidDate: new Date(),
        paidAmount: existing.amount,
        balanceAmount: 0,
        paymentMethod: req.body?.paymentMethod ?? existing.paymentMethod ?? 'manual',
        receivedBy: req.body?.receivedBy ?? req.user.email ?? 'staff',
      },
      { new: true }
    ).populate('member', 'name initials phone email tier');

    // Sync member payment status
    await Member.findOneAndUpdate(
      { _id: payment.member._id, owner: req.user.id },
      { paymentStatus: 'paid' }
    );

    if (existing.subscription) {
      await Subscription.findOneAndUpdate(
        { _id: existing.subscription, owner: req.user.id },
        { nextBillingDate: payment.billingPeriodEnd ?? payment.dueDate }
      );
    }

    res.json(payment);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Unmark payment as paid (revert to pending/overdue)
// @route   PATCH /api/payments/:id/unmark-paid
exports.unmarkPaid = async (req, res) => {
  try {
    const payment = await Payment.findOne({ _id: req.params.id, owner: req.user.id });
    if (!payment) return res.status(404).json({ error: 'Payment not found' });

    const now = new Date();
    const isOverdue = new Date(payment.dueDate) <= now;
    const newStatus = isOverdue ? 'overdue' : 'pending';

    payment.status = newStatus;
    payment.paidDate = undefined;
    payment.paidAmount = 0;
    payment.balanceAmount = payment.amount;
    payment.receivedBy = undefined;
    await payment.save();

    // Sync member payment status
    await Member.findOneAndUpdate({ _id: payment.member, owner: req.user.id }, { paymentStatus: newStatus });

    res.json(payment);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Get payment summary
// @route   GET /api/payments/summary
exports.getPaymentSummary = async (req, res) => {
  try {
    const now = new Date();
    const [summary] = await Payment.aggregate([
      { $match: { owner: new mongoose.Types.ObjectId(req.user.id) } },
      {
        $group: {
          _id: null,
          totalRevenue: {
            $sum: { $cond: [{ $eq: ['$status', 'paid'] }, '$amount', 0] },
          },
          pendingRevenue: {
            $sum: { $cond: [{ $ne: ['$status', 'paid'] }, '$amount', 0] },
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
    ]);

    res.json(summary || { totalRevenue: 0, pendingRevenue: 0, overdueCount: 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Get weekly revenue
// @route   GET /api/payments/weekly
exports.getWeeklyRevenue = async (req, res) => {
  try {
    const since = new Date();
    since.setDate(since.getDate() - 7);

    const data = await Payment.aggregate([
      { $match: { owner: new mongoose.Types.ObjectId(req.user.id), status: 'paid', paidDate: { $gte: since } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$paidDate' } },
          revenue: { $sum: '$amount' },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
