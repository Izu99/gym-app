const router = require('express').Router();
const { getTiers, createTier, updateTier, deleteTier } = require('../controllers/tierController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/', getTiers);
router.post('/', createTier);
router.patch('/:id', updateTier);
router.delete('/:id', deleteTier);

module.exports = router;
