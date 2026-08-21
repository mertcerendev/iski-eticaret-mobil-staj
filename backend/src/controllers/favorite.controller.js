const favoriteService = require('../services/favorite.service');
const { ApiHatasi } = require('../lib/hatalar');

function urunIdAl(req) {
  const id = Number(req.params.productId);

  if (!Number.isInteger(id) || id < 1) {
    throw new ApiHatasi('Geçersiz ürün kimliği.', 400);
  }

  return id;
}

async function listele(req, res) {
  const favoriler = await favoriteService.listele(req.kullanici.id);
  res.status(200).json(favoriler);
}

async function degistir(req, res) {
  const sonuc = await favoriteService.degistir(req.kullanici.id, urunIdAl(req));
  res.status(200).json(sonuc);
}

module.exports = { listele, degistir };
