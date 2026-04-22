const Tier = require('../models/Tier');
const Member = require('../models/Member');

const allowedBillingCycles = new Set([
  'monthly',
  'quarterly',
  'half_yearly',
  'yearly',
]);

function normalizeTierPayload(body = {}) {
  const payload = {};

  if (body.name != null) payload.name = String(body.name).trim();
  if (body.description != null) payload.description = String(body.description).trim();

  if (body.monthlyFee != null) {
    const monthlyFee = Number(body.monthlyFee);
    if (!Number.isFinite(monthlyFee) || monthlyFee < 0) {
      throw new Error('Monthly fee must be a valid non-negative number');
    }
    payload.monthlyFee = monthlyFee;
  }

  if (body.joiningFee != null) {
    const joiningFee = Number(body.joiningFee);
    if (!Number.isFinite(joiningFee) || joiningFee < 0) {
      throw new Error('Joining fee must be a valid non-negative number');
    }
    payload.joiningFee = joiningFee;
  }

  if (body.billingCycle != null) {
    const billingCycle = String(body.billingCycle).trim().toLowerCase();
    if (!allowedBillingCycles.has(billingCycle)) {
      throw new Error(
        'Billing cycle must be monthly, quarterly, half_yearly, or yearly'
      );
    }
    payload.billingCycle = billingCycle;
  }

  if (body.status != null) {
    const status = String(body.status).trim().toLowerCase();
    if (!['active', 'archived'].includes(status)) {
      throw new Error('Status must be active or archived');
    }
    payload.status = status;
    payload.isArchived = status === 'archived';
  }

  return payload;
}

// @desc    Get all tiers
// @route   GET /api/tiers
exports.getTiers = async (req, res) => {
  try {
    const { includeArchived } = req.query;
    const filter = { owner: req.user.id };
    if (includeArchived !== 'true') filter.isArchived = { $ne: true };

    const tiers = await Tier.find(filter).sort({ isArchived: 1, monthlyFee: 1, name: 1 });
    res.json(tiers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Create a tier
// @route   POST /api/tiers
exports.createTier = async (req, res) => {
  try {
    const payload = normalizeTierPayload(req.body);
    if (!payload.name) return res.status(400).json({ error: 'Package name is required' });
    if (payload.monthlyFee == null) {
      return res.status(400).json({ error: 'Monthly fee is required' });
    }
    const tier = await Tier.create({ ...payload, owner: req.user.id });
    res.status(201).json(tier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Update a tier
// @route   PATCH /api/tiers/:id
exports.updateTier = async (req, res) => {
  try {
    const payload = normalizeTierPayload(req.body);
    const tier = await Tier.findOneAndUpdate(
      { _id: req.params.id, owner: req.user.id },
      payload,
      { new: true, runValidators: true }
    );
    if (!tier) return res.status(404).json({ error: 'Tier not found' });
    res.json(tier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Archive a tier
// @route   DELETE /api/tiers/:id
exports.deleteTier = async (req, res) => {
  try {
    const tier = await Tier.findOne({ _id: req.params.id, owner: req.user.id });
    if (!tier) return res.status(404).json({ error: 'Tier not found' });

    const assignedMembers = await Member.countDocuments({
      owner: req.user.id,
      tier: tier._id,
      isActive: true,
    });

    tier.status = 'archived';
    tier.isArchived = true;
    await tier.save();

    res.json({
      message: assignedMembers > 0
          ? 'Package archived. Existing members keep their current assignment.'
          : 'Package archived.',
      assignedMembers,
      tier,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
