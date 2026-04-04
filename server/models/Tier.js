const mongoose = require('mongoose');

const tierSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true }, // e.g. 'BASIC STRENGTH'
  monthlyFee: { type: Number, required: true },
});

module.exports = mongoose.model('Tier', tierSchema);
