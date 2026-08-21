const express = require('express');

const productController = require('../controllers/product.controller');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

router.get('/', productController.listele);
router.get('/:id', productController.detay);

router.post('/', auth, requireAdmin, productController.olustur);
router.put('/:id', auth, requireAdmin, productController.guncelle);
router.delete('/:id', auth, requireAdmin, productController.sil);

module.exports = router;