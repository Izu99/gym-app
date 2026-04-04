const mongoose = require('mongoose');

const memberSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name: { type: String, required: true, trim: true },
    initials: { type: String, required: true, maxlength: 3 },
    email: { type: String, required: true, lowercase: true },
    phone: { type: String },
    tier: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Tier',
      required: true,
    },
    memberSince: { type: Date, default: Date.now },
    paymentStatus: {
      type: String,
      enum: ['paid', 'overdue', 'pending'],
      default: 'pending',
    },
    nextPaymentDate: { type: Date },
    monthlyFee: { type: Number, required: true },
    isAtRisk: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// Unique email per owner
memberSchema.index({ owner: 1, email: 1 }, { unique: true });

// Virtual: tier label
memberSchema.virtual('tierLabel').get(function () {
  if (this.tier && this.tier.name) {
    return this.tier.name.toUpperCase();
  }
  return 'UNKNOWN';
});

memberSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Member', memberSchema);
