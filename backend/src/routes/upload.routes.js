const express = require('express');

const uploadController = require('../controllers/upload.controller');
const { yukle } = require('../middleware/upload');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

router.post('/', auth, requireAdmin, yukle.single('image'), uploadController.gorselYukle);

module.exports = router;