/**
 * Seed script — populates MongoDB with sample data matching the Flutter mock data.
 * Run: node seed.js
 */
require('dotenv').config({ override: true });
const mongoose = require('mongoose');
const Member = require('./models/Member');
const User = require('./models/User');
const Attendance = require('./models/Attendance');
const Payment = require('./models/Payment');
const Tier = require('./models/Tier');

const tiersData = [
  { id: 'basic', name: 'BASIC STRENGTH', monthlyFee: 5000 },
  { id: 'standard', name: 'STANDARD', monthlyFee: 8000 },
  { id: 'elitePro', name: 'ELITE PRO', monthlyFee: 12000 },
  { id: 'vip', name: 'VIP ACCESS', monthlyFee: 25000 },
  { id: 'master', name: 'MASTER', monthlyFee: 15000 },
];

const membersData = [
  { name: 'Marcus Thorne', initials: 'MT', email: 'marcus@ironpulse.gym', tier: 'elitePro', monthlyFee: 12000, paymentStatus: 'paid', nextPaymentDate: new Date('2024-12-10') },
  { name: 'Sarah Jenkins', initials: 'SJ', email: 'sarah@ironpulse.gym', tier: 'basic', monthlyFee: 5000, paymentStatus: 'paid', nextPaymentDate: new Date('2024-11-22'), isAtRisk: true },
  { name: 'David Kim', initials: 'DK', email: 'david@ironpulse.gym', tier: 'standard', monthlyFee: 8000, paymentStatus: 'overdue', nextPaymentDate: new Date('2024-10-15') },
  { name: 'Elena Rodriguez', initials: 'ER', email: 'elena@ironpulse.gym', tier: 'vip', monthlyFee: 25000, paymentStatus: 'paid', nextPaymentDate: new Date('2024-12-05') },
  { name: 'Aria Vance', initials: 'AV', email: 'aria@ironpulse.gym', tier: 'basic', monthlyFee: 5000, paymentStatus: 'pending', nextPaymentDate: new Date('2024-11-05') },
];

async function seed() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB for seeding...');

  // Clear existing
  await User.deleteMany({});
  await Member.deleteMany({});
  await Attendance.deleteMany({});
  await Payment.deleteMany({});
  await Tier.deleteMany({});

  // Tiers
  await Tier.insertMany(tiersData);
  console.log('Tiers seeded');

  // Admin User
  const admin = await User.create({
    email: 'owner@ironpulse.gym',
    password: 'password',
    name: 'System Owner',
    role: 'owner',
  });
  console.log('Admin user seeded (owner@ironpulse.gym / password)');

  // Members
  const members = await Member.insertMany(membersData);
  console.log(`${members.length} members seeded`);

  // Attendance
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const attendance = members.slice(0, 3).map((m) => ({
    member: m._id,
    date: today,
    status: 'present',
    checkinTime: new Date(),
    session: 'Morning',
  }));
  await Attendance.insertMany(attendance);
  console.log('Attendance seeded');

  // Payments
  const payments = members.map((m) => ({
    member: m._id,
    amount: m.monthlyFee,
    status: m.paymentStatus,
    dueDate: m.nextPaymentDate || new Date(),
    paidDate: m.paymentStatus === 'paid' ? new Date() : undefined,
  }));
  await Payment.insertMany(payments);
  console.log(`${payments.length} payments seeded`);

  await mongoose.disconnect();
  console.log('Done.');
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
