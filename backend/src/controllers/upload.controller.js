const { ApiHatasi } = require('../lib/hatalar');

function gorselYukle(req, res) {
  if (!req.file) {
    throw new ApiHatasi('Dosya gönderilmedi. Alan adı "image" olmalıdır.', 400);
  }

  res.status(201).json({
    url: `/uploads/${req.file.filename}`,
    size: req.file.size,
    mimetype: req.file.mimetype,
  });
}

module.exports = { gorselYukle };