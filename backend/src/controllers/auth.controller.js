const authService = require('../services/auth.service');

async function kayitOl(req, res) {
  const sonuc = await authService.kayitOl(req.body);
  res.status(201).json(sonuc);
}

async function girisYap(req, res) {
  const sonuc = await authService.girisYap(req.body);
  res.status(200).json(sonuc);
}

async function profilim(req, res) {
  const kullanici = await authService.profilGetir(req.kullanici.id);
  res.status(200).json(kullanici);
}

async function profilGuncelle(req, res) {
  const kullanici = await authService.profilGuncelle(req.kullanici.id, req.body);
  res.status(200).json(kullanici);
}

async function parolaDegistir(req, res) {
  await authService.parolaDegistir(req.kullanici.id, req.body);
  res.status(204).send();
}

module.exports = { kayitOl, girisYap, profilim, profilGuncelle, parolaDegistir };