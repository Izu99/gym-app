const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
    tier: { type: mongoose.Schema.Types.ObjectId, ref: 'Tier', required: true },
    packageName: { type: String, required: true },
    billingAmount: { type: Number, required: true, min: 0 },
    billingCycle: {
      type: String,
      enum: ['monthly', 'quarterly', 'half_yearly', 'yearly'],
      default: 'monthly',
    },
    startDate: { type: Date, default: Date.now },
    nextBillingDate: { type: Date },
    status: {
      type: String,
      enum: ['active', 'frozen', 'cancelled', 'expired'],
      default: 'active',
    },
    changeMode: {
      type: String,
      enum: ['immediate', 'next_cycle'],
      default: 'immediate',
    },
    endedAt: { type: Date },
  },
  { timestamps: true }
);

subscriptionSchema.index({ owner: 1, member: 1, status: 1 });

module.exports = mongoose.model('Subscription', subscriptionSchema);
