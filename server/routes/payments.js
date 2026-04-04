const router = require('express').Router();
const auth = require('../middleware/auth');
const {
  getPayments,
  createPayment,
  markPaid,
  unmarkPaid,
  getPaymentSummary,
  getWeeklyRevenue,
} = require('../controllers/paymentController');

router.use(auth);

router.get('/', getPayments);
router.post('/', createPayment);
router.patch('/:id/mark-paid', markPaid);
router.patch('/:id/unmark-paid', unmarkPaid);
router.get('/summary', getPaymentSummary);
router.get('/weekly', getWeeklyRevenue);

module.exports = router;
