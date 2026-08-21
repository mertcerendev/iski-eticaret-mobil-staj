const cartService = require('../services/cart.service');
const { ApiHatasi } = require('../lib/hatalar');

function urunIdAl(req) {
  const id = Number(req.params.productId);

  if (!Number.isInteger(id) || id < 1) {
    throw new ApiHatasi('Geçersiz ürün kimliği.', 400);
  }

  return id;
}

async function listele(req, res) {
  const sepet = await cartService.listele(req.kullanici.id);
  res.status(200).json(sepet);
}

async function ekle(req, res) {
  const sepet = await cartService.ekle(req.kullanici.id, req.body);
  res.status(201).json(sepet);
}

async function adetGuncelle(req, res) {
  const sepet = await cartService.adetGuncelle(req.kullanici.id, urunIdAl(req), req.body);
  res.status(200).json(sepet);
}

async function cikar(req, res) {
  const sepet = await cartService.cikar(req.kullanici.id, urunIdAl(req));
  res.status(200).json(sepet);
}

async function temizle(req, res) {
  const sepet = await cartService.temizle(req.kullanici.id);
  res.status(200).json(sepet);
}

module.exports = { listele, ekle, adetGuncelle, cikar, temizle };
