const { dogrula } = require('../lib/token');
const { ApiHatasi } = require('../lib/hatalar');

function auth(req, res, next) {
  const baslik = req.headers.authorization;

  if (!baslik || !baslik.startsWith('Bearer ')) {
    throw new ApiHatasi('Bu işlem için giriş yapmalısınız.', 401);
  }

  const token = baslik.slice(7);

  let icerik;
  try {
    icerik = dogrula(token);
  } catch (hata) {
    throw new ApiHatasi('Oturumunuz geçersiz veya süresi dolmuş.', 401);
  }

  req.kullanici = { id: icerik.id, role: icerik.role };

  next();
}

module.exports = auth;