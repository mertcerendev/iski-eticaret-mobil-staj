const { ApiHatasi } = require('../lib/hatalar');

function requireAdmin(req, res, next) {
  if (!req.kullanici) {
    throw new ApiHatasi('Bu işlem için giriş yapmalısınız.', 401);
  }

  if (req.kullanici.role !== 'ADMIN') {
    throw new ApiHatasi('Bu işlem için yönetici yetkisi gerekir.', 403);
  }

  next();
}

module.exports = requireAdmin;