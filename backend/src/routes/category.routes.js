const express = require('express');

const categoryController = require('../controllers/category.controller');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

router.get('/', categoryController.listele);
router.get('/:id', categoryController.detay);

router.post('/', auth, requireAdmin, categoryController.olustur);
router.put('/:id', auth, requireAdmin, categoryController.guncelle);
router.delete('/:id', auth, requireAdmin, categoryController.sil);

module.exports = router;