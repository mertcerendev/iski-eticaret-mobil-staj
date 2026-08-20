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

module.exports = { kayitOl, girisYap, profilim };