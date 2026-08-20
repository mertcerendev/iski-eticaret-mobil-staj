require('dotenv/config');

const jwt = require('jsonwebtoken');

if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET tanımlı değil. backend/.env dosyasını kontrol edin.');
}

const GIZLI_ANAHTAR = process.env.JWT_SECRET;
const GECERLILIK = process.env.JWT_EXPIRES_IN || '7d';

function imzala(icerik) {
  return jwt.sign(icerik, GIZLI_ANAHTAR, { expiresIn: GECERLILIK });
}

function dogrula(token) {
  return jwt.verify(token, GIZLI_ANAHTAR);
}

module.exports = { imzala, dogrula };