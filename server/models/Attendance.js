const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    member: { type: mongoose.Schema.Types.ObjectId, ref: 'Member', required: true },
    date: { type: Date, required: true },
    status: {
      type: String,
      enum: ['present', 'absent', 'pending'],
      default: 'pending',
    },
    session: { type: String }, // e.g. "Morning Blast", "Power Hour"
    checkinTime: { type: Date },
    checkoutTime: { type: Date },
  },
  { timestamps: true }
);

// Compound index: one record per member per day
attendanceSchema.index({ member: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
