const router = require('express').Router();
const auth = require('../middleware/auth');
const {
  getAttendance,
  markAttendance,
  getAttendanceStats,
} = require('../controllers/attendanceController');

router.use(auth);

router.get('/', getAttendance);
router.post('/', markAttendance);
router.get('/stats', getAttendanceStats);

module.exports = router;
