const express = require('express');

const orderController = require('../controllers/order.controller');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

router.use(auth);

router.post('/', orderController.olustur);
router.get('/', orderController.listele);

router.get('/admin/all', requireAdmin, orderController.hepsiniGetir);
router.patch('/:id/status', requireAdmin, orderController.durumGuncelle);

router.get('/:id', orderController.detay);

module.exports = router;
