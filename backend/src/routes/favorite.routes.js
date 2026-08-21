const express = require('express');

const favoriteController = require('../controllers/favorite.controller');
const auth = require('../middleware/auth');

const router = express.Router();

router.use(auth);

router.get('/', favoriteController.listele);
router.post('/:productId', favoriteController.degistir);

module.exports = router;
