const multer = require('multer');

const { ApiHatasi } = require('../lib/hatalar');
const { EN_FAZLA_BOYUT_MB } = require('./upload');

const MULTER_MESAJLARI = {
  LIMIT_FILE_SIZE: `Dosya boyutu ${EN_FAZLA_BOYUT_MB} MB sınırını aşıyor.`,
  LIMIT_FILE_COUNT: 'Aynı anda yalnızca bir dosya yüklenebilir.',
  LIMIT_UNEXPECTED_FILE: 'Beklenmeyen alan adı. Dosya alanının adı "image" olmalıdır.',
};

function errorHandler(hata, req, res, next) {
  if (hata instanceof ApiHatasi) {
    return res.status(hata.durumKodu).json({ message: hata.message });
  }

  if (hata instanceof multer.MulterError) {
    return res.status(400).json({
      message: MULTER_MESAJLARI[hata.code] ?? 'Dosya yüklenemedi.',
    });
  }

  console.error('Beklenmeyen hata:', hata);
  res.status(500).json({ message: 'Sunucuda beklenmeyen bir hata oluştu.' });
}

module.exports = errorHandler;