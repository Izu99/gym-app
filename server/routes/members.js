const router = require('express').Router();
const auth = require('../middleware/auth');
const {
  getMembers,
  getMemberById,
  createMember,
  updateMember,
  deleteMember,
} = require('../controllers/memberController');

router.use(auth);

router.get('/', getMembers);
router.get('/:id', getMemberById);
router.post('/', createMember);
router.patch('/:id', updateMember);
router.delete('/:id', deleteMember);

module.exports = router;
