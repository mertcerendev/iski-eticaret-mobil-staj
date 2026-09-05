/**
 * Uçtan uca duman testi.
 *
 * Bütün ana akışları sırayla çağırıp dönen HTTP kodunu beklenenle karşılaştırır.
 * Sunum öncesi ya da bir değişiklikten sonra "hiçbir şey kırılmadı mı" sorusuna
 * bir dakikada cevap verir.
 *
 * Kullanım (sunucu ve veritabanı ayaktayken):
 *     node scripts/duman-testi.js
 *
 * Çıkış kodu: hepsi geçtiyse 0, bir tanesi bile kaldıysa 1.
 */
const TEMEL = process.env.API_TEMEL || 'http://localhost:3000/api';

const HESAP = { email: 'admin@eticaret.com', password: 'Admin123!' };

let gecti = 0;
let kaldi = 0;
let token = null;

async function cagir(yol, { yontem = 'GET', govde, bekle = 200, yetkili } = {}) {
  const basliklar = { 'Content-Type': 'application/json' };

  if (yetkili && token) {
    basliklar.Authorization = `Bearer ${token}`;
  }

  const yanit = await fetch(TEMEL + yol, {
    method: yontem,
    headers: basliklar,
    body: govde === undefined ? undefined : JSON.stringify(govde),
  });

  const tamam = yanit.status === bekle;
  const isaret = tamam ? '  [OK]  ' : '  [HATA]';

  console.log(
    `${isaret} ${yontem.padEnd(6)} ${yol.padEnd(34)} -> ${yanit.status} (beklenen ${bekle})`
  );

  if (tamam) gecti += 1;
  else kaldi += 1;

  // 204 gövdesiz döner; JSON çözmeye çalışmak hata verirdi.
  if (yanit.status === 204) return null;

  return yanit.json().catch(() => null);
}

async function main() {
  console.log('1) Sağlık ve kimlik');
  await cagir('/health');

  const oturum = await cagir('/auth/login', { yontem: 'POST', govde: HESAP });
  token = oturum?.token;

  if (!token) {
    console.error('\nGiriş yapılamadı; sunucu veya veritabanı kapalı olabilir.');
    process.exit(1);
  }

  await cagir('/auth/login', {
    yontem: 'POST',
    govde: { ...HESAP, password: 'yanlis' },
    bekle: 401,
  });
  await cagir('/auth/me', { yetkili: true });

  console.log('\n2) Katalog');
  await cagir('/categories');
  await cagir('/products?page=1&limit=5');
  await cagir('/products?search=fare');
  await cagir('/products?sort=ucuz&page=1&limit=3');
  // Beyaz listede olmayan sıralama değeri sessizce yok sayılmaz.
  await cagir('/products?sort=gecersiz', { bekle: 400 });

  console.log('\n3) Favori ve sepet');
  await cagir('/favorites', { yetkili: true });
  await cagir('/cart', { yetkili: true });
  await cagir('/cart', {
    yontem: 'POST',
    govde: { productId: 17, quantity: 2 },
    bekle: 201,
    yetkili: true,
  });
  await cagir('/cart/17', {
    yontem: 'PUT',
    govde: { quantity: 3 },
    yetkili: true,
  });
  // Adet sınırı stok denetiminden ÖNCE uygulanıyor, bu yüzden 400 (409 değil).
  await cagir('/cart', {
    yontem: 'POST',
    govde: { productId: 17, quantity: 9999 },
    bekle: 400,
    yetkili: true,
  });

  console.log('\n4) Sipariş ve ödeme');
  const adres = 'Guzeltepe Mah. Osmanpasa Cd. No 7, Eyupsultan/Istanbul';

  // Luhn denetiminden geçmeyen kart reddedilmeli.
  await cagir('/orders', {
    yontem: 'POST',
    govde: {
      addressText: adres,
      cardNumber: '1111',
      cardExpiry: '12/28',
      cardCvv: '123',
      cardHolderName: 'MERT CEREN',
    },
    bekle: 400,
    yetkili: true,
  });

  const siparis = await cagir('/orders', {
    yontem: 'POST',
    govde: {
      addressText: adres,
      cardNumber: '4242424242424242',
      cardExpiry: '12/28',
      cardCvv: '123',
      cardHolderName: 'MERT CEREN',
    },
    bekle: 201,
    yetkili: true,
  });

  console.log(
    `         -> SP-${String(siparis.id).padStart(6, '0')} | ` +
      `durum=${siparis.status} | kart=${siparis.cardLast4}`
  );

  await cagir('/orders', { yetkili: true });
  await cagir(`/orders/${siparis.id}`, { yetkili: true });

  console.log('\n5) Yönetici');
  await cagir('/orders/admin/all?page=1&limit=5', { yetkili: true });
  await cagir(`/orders/${siparis.id}/status`, {
    yontem: 'PATCH',
    govde: { status: 'PREPARING' },
    yetkili: true,
  });
  // Geçiş tablosuna uymayan sıçrama reddedilmeli.
  await cagir(`/orders/${siparis.id}/status`, {
    yontem: 'PATCH',
    govde: { status: 'DELIVERED' },
    bekle: 409,
    yetkili: true,
  });
  // Belirteçsiz yönetici isteği reddedilmeli.
  await cagir('/products', {
    yontem: 'POST',
    govde: { name: 'x' },
    bekle: 401,
  });

  console.log('\n6) Profil');
  await cagir('/auth/me', {
    yontem: 'PATCH',
    govde: { fullName: 'Sistem Yöneticisi' },
    yetkili: true,
  });
  // Hatalı mevcut parola 400 döner; 401 dönseydi mobil istemci kullanıcıyı
  // oturumdan atardı.
  await cagir('/auth/me/password', {
    yontem: 'PATCH',
    govde: { currentPassword: 'yanlis', newPassword: 'YeniParola1' },
    bekle: 400,
    yetkili: true,
  });

  console.log(`\n${'='.repeat(56)}`);
  console.log(`SONUÇ: ${gecti} geçti, ${kaldi} kaldı`);

  process.exit(kaldi > 0 ? 1 : 0);
}

main().catch((hata) => {
  console.error('\nDuman testi çalışamadı:', hata.message);
  process.exit(1);
});
