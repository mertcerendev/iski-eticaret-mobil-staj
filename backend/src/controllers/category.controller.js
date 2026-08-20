const categoryService = require('../services/category.service');
const { ApiHatasi } = require('../lib/hatalar');

function idAl(req) {
  const id = Number(req.params.id);

  if (!Number.isInteger(id) || id < 1) {
    throw new ApiHatasi('Geçersiz kategori kimliği.', 400);
  }

  return id;
}

async function listele(req, res) {
  const kategoriler = await categoryService.hepsiniGetir();
  res.status(200).json(kategoriler);
}

async function detay(req, res) {
  const kategori = await categoryService.idIleGetir(idAl(req));
  res.status(200).json(kategori);
}

async function olustur(req, res) {
  const kategori = await categoryService.olustur(req.body);
  res.status(201).json(kategori);
}

async function guncelle(req, res) {
  const kategori = await categoryService.guncelle(idAl(req), req.body);
  res.status(200).json(kategori);
}

async function sil(req, res) {
  await categoryService.sil(idAl(req));
  res.status(204).send();
}

module.exports = { listele, detay, olustur, guncelle, sil };