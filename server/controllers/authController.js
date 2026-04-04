const jwt = require('jsonwebtoken');
const User = require('../models/User');

const signToken = (user) =>
  jwt.sign(
    { id: user._id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

// @desc    Register new user
// @route   POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { email, password, name, companyName, companyAddress, phoneNumber } = req.body;
    if (!email || !password || !name)
      return res.status(400).json({ error: 'email, password and name are required' });

    const existing = await User.findOne({ email });
    if (existing) return res.status(409).json({ error: 'Email already registered' });

    const user = await User.create({ email, password, name, companyName, companyAddress, phoneNumber });
    res.status(201).json({ 
      token: signToken(user), 
      user: { 
        id: user._id, email, name, role: user.role, 
        companyName: user.companyName, 
        companyAddress: user.companyAddress, 
        phoneNumber: user.phoneNumber 
      } 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Login user
// @route   POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password)))
      return res.status(401).json({ error: 'Invalid credentials' });

    res.json({ 
      token: signToken(user), 
      user: { 
        id: user._id, email: user.email, name: user.name, role: user.role,
        companyName: user.companyName, 
        companyAddress: user.companyAddress, 
        phoneNumber: user.phoneNumber 
      } 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Get current user
// @route   GET /api/auth/me
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// @desc    Update user profile
// @route   PATCH /api/auth/profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, companyName, companyAddress, phoneNumber } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { name, companyName, companyAddress, phoneNumber },
      { new: true, runValidators: true }
    ).select('-password');
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// @desc    Update password
// @route   PATCH /api/auth/password
exports.updatePassword = async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) return res.status(400).json({ error: 'Password is required' });

    const user = await User.findById(req.user.id);
    user.password = password;
    await user.save();

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};
