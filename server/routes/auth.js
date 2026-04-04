const router = require('express').Router();
const { register, login, updateProfile, updatePassword, getMe } = require('../controllers/authController');
const auth = require('../middleware/auth');

router.post('/register', register);
router.post('/login', login);

router.use(auth);
router.get('/me', getMe);
router.patch('/profile', updateProfile);
router.patch('/password', updatePassword);

module.exports = router;
