const router = require('express').Router();
const auth = require('../middleware/auth');
const {
  getAttendance,
  getMemberAttendanceCalendar,
  markAttendance,
  getAttendanceStats,
} = require('../controllers/attendanceController');

router.use(auth);

router.get('/', getAttendance);
router.get('/member-calendar', getMemberAttendanceCalendar);
router.post('/', markAttendance);
router.get('/stats', getAttendanceStats);

module.exports = router;
