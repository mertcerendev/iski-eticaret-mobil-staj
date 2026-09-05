const express = require('express');

const authController = require('../controllers/auth.controller');
const auth = require('../middleware/auth');

const router = express.Router();

router.post('/register', authController.kayitOl);
router.post('/login', authController.girisYap);
router.get('/me', auth, authController.profilim);
router.patch('/me', auth, authController.profilGuncelle);
router.patch('/me/password', auth, authController.parolaDegistir);

module.exports = router;