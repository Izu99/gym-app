const mongoose = require('mongoose');

const tierSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true, trim: true },
    monthlyFee: { type: Number, required: true, min: 0 },
    description: { type: String, default: '', trim: true, maxlength: 500 },
    billingCycle: {
      type: String,
      enum: ['monthly', 'quarterly', 'yearly'],
      default: 'monthly',
    },
    joiningFee: { type: Number, default: 0, min: 0 },
    status: {
      type: String,
      enum: ['active', 'archived'],
      default: 'active',
    },
    isArchived: { type: Boolean, default: false },
  },
  { timestamps: true }
);

tierSchema.pre('save', function syncArchiveState(next) {
  this.isArchived = this.status === 'archived';
  next();
});

module.exports = mongoose.model('Tier', tierSchema);
