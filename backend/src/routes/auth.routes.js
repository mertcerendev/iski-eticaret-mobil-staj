const express = require('express');

const authController = require('../controllers/auth.controller');
const auth = require('../middleware/auth');

const router = express.Router();

router.post('/register', authController.kayitOl);
router.post('/login', authController.girisYap);
router.get('/me', auth, authController.profilim);

module.exports = router;