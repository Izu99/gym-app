const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
    subscription: { type: mongoose.Schema.Types.ObjectId, ref: 'Subscription' },
    invoiceNumber: { type: String },
    plan: { type: String, required: true },
    amount: { type: Number, required: true },
    paidAmount: { type: Number, default: 0 },
    discountAmount: { type: Number, default: 0 },
    balanceAmount: { type: Number, default: 0 },
    paymentMethod: {
      type: String,
      enum: ['cash', 'bank_transfer', 'card', 'manual', 'other'],
      default: 'manual',
    },
    receivedBy: { type: String },
    billingPeriodStart: { type: Date },
    billingPeriodEnd: { type: Date },
    dueDate: { type: Date, required: true },
    paidDate: { type: Date },
    status: {
      type: String,
      enum: ['paid', 'overdue', 'pending', 'partial', 'cancelled'],
      default: 'pending',
    },
    notes: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Payment', paymentSchema);
