const productService = require('../services/product.service');
const { ApiHatasi } = require('../lib/hatalar');

function idAl(req) {
  const id = Number(req.params.id);

  if (!Number.isInteger(id) || id < 1) {
    throw new ApiHatasi('Geçersiz ürün kimliği.', 400);
  }

  return id;
}

async function listele(req, res) {
  const sonuc = await productService.listele(req.query);
  res.status(200).json(sonuc);
}

async function detay(req, res) {
  const urun = await productService.idIleGetir(idAl(req));
  res.status(200).json(urun);
}

async function olustur(req, res) {
  const urun = await productService.olustur(req.body);
  res.status(201).json(urun);
}

async function guncelle(req, res) {
  const urun = await productService.guncelle(idAl(req), req.body);
  res.status(200).json(urun);
}

async function sil(req, res) {
  await productService.sil(idAl(req));
  res.status(204).send();
}

module.exports = { listele, detay, olustur, guncelle, sil };