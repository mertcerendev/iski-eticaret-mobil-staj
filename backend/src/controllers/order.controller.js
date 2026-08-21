const orderService = require('../services/order.service');
const { ApiHatasi } = require('../lib/hatalar');

function idAl(req) {
  const id = Number(req.params.id);

  if (!Number.isInteger(id) || id < 1) {
    throw new ApiHatasi('Geçersiz sipariş kimliği.', 400);
  }

  return id;
}

async function olustur(req, res) {
  const siparis = await orderService.olustur(req.kullanici.id, req.body);
  res.status(201).json(siparis);
}

async function listele(req, res) {
  const siparisler = await orderService.listele(req.kullanici.id);
  res.status(200).json(siparisler);
}

async function detay(req, res) {
  const siparis = await orderService.detay(req.kullanici.id, idAl(req));
  res.status(200).json(siparis);
}

async function hepsiniGetir(req, res) {
  const sonuc = await orderService.hepsiniGetir(req.query);
  res.status(200).json(sonuc);
}

async function durumGuncelle(req, res) {
  const siparis = await orderService.durumGuncelle(idAl(req), req.body);
  res.status(200).json(siparis);
}

module.exports = { olustur, listele, detay, hepsiniGetir, durumGuncelle };
