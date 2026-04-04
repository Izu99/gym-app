const Tier = require('../models/Tier');

// @desc    Get all tiers
// @route   GET /api/tiers
exports.getTiers = async (req, res) => {
  try {
    const tiers = await Tier.find({ owner: req.user.id });
    res.json(tiers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Create a tier
// @route   POST /api/tiers
exports.createTier = async (req, res) => {
  try {
    const tier = await Tier.create({ ...req.body, owner: req.user.id });
    res.status(201).json(tier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Update a tier
// @route   PATCH /api/tiers/:id
exports.updateTier = async (req, res) => {
  try {
    const tier = await Tier.findOneAndUpdate(
      { _id: req.params.id, owner: req.user.id },
      req.body,
      { new: true }
    );
    if (!tier) return res.status(404).json({ error: 'Tier not found' });
    res.json(tier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Delete a tier
// @route   DELETE /api/tiers/:id
exports.deleteTier = async (req, res) => {
  try {
    const tier = await Tier.findOneAndDelete({ _id: req.params.id, owner: req.user.id });
    if (!tier) return res.status(404).json({ error: 'Tier not found' });
    res.json({ message: 'Tier deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
