const express = require('express');

const cartController = require('../controllers/cart.controller');
const auth = require('../middleware/auth');

const router = express.Router();

router.use(auth);

router.get('/', cartController.listele);
router.post('/', cartController.ekle);
router.put('/:productId', cartController.adetGuncelle);
router.delete('/:productId', cartController.cikar);
router.delete('/', cartController.temizle);

module.exports = router;
