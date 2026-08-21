const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');

const { ApiHatasi } = require('../lib/hatalar');

const KLASOR = path.join(__dirname, '..', '..', 'uploads');
const EN_FAZLA_BOYUT_MB = 2;

const IZINLI_TIPLER = {
  'image/png': '.png',
  'image/jpeg': '.jpg',
  'image/webp': '.webp',
};

fs.mkdirSync(KLASOR, { recursive: true });

const depolama = multer.diskStorage({
  destination: (req, file, cb) => cb(null, KLASOR),

  filename: (req, file, cb) => {
    const uzanti = IZINLI_TIPLER[file.mimetype];
    const benzersiz = `${Date.now()}-${crypto.randomBytes(6).toString('hex')}`;
    cb(null, `urun-${benzersiz}${uzanti}`);
  },
});

function tipSuzgeci(req, file, cb) {
  if (IZINLI_TIPLER[file.mimetype]) {
    cb(null, true);
    return;
  }

  cb(new ApiHatasi('Sadece PNG, JPEG ve WebP dosyaları yüklenebilir.', 400));
}

const yukle = multer({
  storage: depolama,
  fileFilter: tipSuzgeci,
  limits: { fileSize: EN_FAZLA_BOYUT_MB * 1024 * 1024, files: 1 },
});

module.exports = { yukle, EN_FAZLA_BOYUT_MB };