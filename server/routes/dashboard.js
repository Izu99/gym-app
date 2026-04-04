const router = require('express').Router();
const auth = require('../middleware/auth');
const {
  getDashboardStats,
  getTierBreakdown,
} = require('../controllers/dashboardController');

router.use(auth);

router.get('/stats', getDashboardStats);
router.get('/tier-breakdown', getTierBreakdown);

module.exports = router;
