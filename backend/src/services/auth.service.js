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

/**
 * Kullanıcının kendi adını günceller.
 *
 * E-posta değiştirilemiyor: kimliğin kendisi ve giriş anahtarı. Değişmesi
 * benzersizlik denetimi, doğrulama postası ve oturum tazeleme gerektirirdi;
 * bu projenin kapsamı dışında tutuldu.
 */
async function profilGuncelle(kullaniciId, { fullName }) {
  if (!fullName || !String(fullName).trim()) {
    throw new ApiHatasi('Ad soyad zorunludur.', 400);
  }

  const temiz = String(fullName).trim();

  if (temiz.length < 3 || temiz.length > 100) {
    throw new ApiHatasi('Ad soyad 3-100 karakter olmalıdır.', 400);
  }

  const kullanici = await prisma.user.update({
    where: { id: kullaniciId },
    data: { fullName: temiz },
  });

  return kullaniciyiTemizle(kullanici);
}

/**
 * Parola değiştirme.
 *
 * Mevcut parola da isteniyor: oturumu ele geçiren birinin parolayı tek
 * başına değiştirip hesabı kilitlemesi engelleniyor.
 */
async function parolaDegistir(kullaniciId, { currentPassword, newPassword }) {
  if (!currentPassword || !newPassword) {
    throw new ApiHatasi('Mevcut ve yeni parola zorunludur.', 400);
  }

  if (newPassword.length < 8) {
    throw new ApiHatasi('Yeni parola en az 8 karakter olmalıdır.', 400);
  }

  if (currentPassword === newPassword) {
    throw new ApiHatasi('Yeni parola eskisiyle aynı olamaz.', 400);
  }

  const kullanici = await prisma.user.findUnique({ where: { id: kullaniciId } });

  if (!kullanici) {
    throw new ApiHatasi('Kullanıcı bulunamadı.', 404);
  }

  const dogru = await bcrypt.compare(currentPassword, kullanici.passwordHash);

  if (!dogru) {
    // Bilerek 401 DEĞİL: istemcideki HTTP katmanı 401'i "oturum düştü" olarak
    // yorumlayıp token'ı siliyor ve kullanıcıyı giriş ekranına atıyor. Burada
    // oturum geçerli, hatalı olan yalnızca gövdedeki parola. 401 dönseydi
    // kullanıcı parolasını bir kez yanlış yazdığında uygulamadan atılırdı.
    throw new ApiHatasi('Mevcut parolanız hatalı.', 400);
  }

  await prisma.user.update({
    where: { id: kullaniciId },
    data: { passwordHash: await bcrypt.hash(newPassword, TUR_SAYISI) },
  });
}

module.exports = {
  kayitOl,
  girisYap,
  profilGetir,
  profilGuncelle,
  parolaDegistir,
};