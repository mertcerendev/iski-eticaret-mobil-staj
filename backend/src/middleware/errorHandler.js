const { ApiHatasi } = require('../lib/hatalar');

function errorHandler(hata, req, res, next) {
  if (hata instanceof ApiHatasi) {
    return res.status(hata.durumKodu).json({ message: hata.message });
  }

  console.error('Beklenmeyen hata:', hata);
  res.status(500).json({ message: 'Sunucuda beklenmeyen bir hata oluştu.' });
}

module.exports = errorHandler;