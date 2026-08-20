const bcrypt = require('bcryptjs');

const prisma = require('../lib/prisma');
const { imzala } = require('../lib/token');
const { ApiHatasi } = require('../lib/hatalar');

const TUR_SAYISI = 10;
const EPOSTA_DESENI = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function kullaniciyiTemizle(kullanici) {
  const { passwordHash, ...guvenliAlanlar } = kullanici;
  return guvenliAlanlar;
}

function oturumYaniti(kullanici) {
  return {
    user: kullaniciyiTemizle(kullanici),
    token: imzala({ id: kullanici.id, role: kullanici.role }),
  };
}

async function kayitOl({ email, password, fullName }) {
  if (!email || !password || !fullName) {
    throw new ApiHatasi('E-posta, parola ve ad soyad zorunludur.', 400);
  }

  const temizEmail = email.trim().toLowerCase();

  if (!EPOSTA_DESENI.test(temizEmail)) {
    throw new ApiHatasi('Geçerli bir e-posta adresi giriniz.', 400);
  }

  if (password.length < 8) {
    throw new ApiHatasi('Parola en az 8 karakter olmalıdır.', 400);
  }

  const mevcut = await prisma.user.findUnique({ where: { email: temizEmail } });
  if (mevcut) {
    throw new ApiHatasi('Bu e-posta adresi zaten kayıtlı.', 409);
  }

  const passwordHash = await bcrypt.hash(password, TUR_SAYISI);

  const kullanici = await prisma.user.create({
    data: {
      email: temizEmail,
      passwordHash,
      fullName: fullName.trim(),
    },
  });

  return oturumYaniti(kullanici);
}

async function girisYap({ email, password }) {
  if (!email || !password) {
    throw new ApiHatasi('E-posta ve parola zorunludur.', 400);
  }

  const temizEmail = email.trim().toLowerCase();

  const kullanici = await prisma.user.findUnique({ where: { email: temizEmail } });
  if (!kullanici) {
    throw new ApiHatasi('E-posta veya parola hatalı.', 401);
  }

  const parolaDogru = await bcrypt.compare(password, kullanici.passwordHash);
  if (!parolaDogru) {
    throw new ApiHatasi('E-posta veya parola hatalı.', 401);
  }

  return oturumYaniti(kullanici);
}

async function profilGetir(kullaniciId) {
  const kullanici = await prisma.user.findUnique({ where: { id: kullaniciId } });

  if (!kullanici) {
    throw new ApiHatasi('Kullanıcı bulunamadı.', 404);
  }

  return kullaniciyiTemizle(kullanici);
}

module.exports = { kayitOl, girisYap, profilGetir };