const { Prisma } = require('@prisma/client');

const prisma = require('../lib/prisma');
const { ApiHatasi } = require('../lib/hatalar');

const VARSAYILAN_LIMIT = 10;
const EN_FAZLA_LIMIT = 50;

const DURUM_GECISLERI = {
  PENDING: ['PAID', 'CANCELLED'],
  PAID: ['PREPARING', 'CANCELLED'],
  PREPARING: ['SHIPPED', 'CANCELLED'],
  SHIPPED: ['DELIVERED'],
  DELIVERED: [],
  CANCELLED: [],
};

const SIPARIS_ICERIGI = {
  items: {
    include: {
      product: { select: { id: true, name: true, imageUrl: true, isActive: true } },
    },
  },
};

function bosMu(deger) {
  return deger === undefined || deger === null || String(deger).trim() === '';
}

function tamSayiAl(deger, alanAdi) {
  const sayi = Number(deger);

  if (!Number.isInteger(sayi) || sayi < 1) {
    throw new ApiHatasi(`${alanAdi} 1 veya daha büyük bir tam sayı olmalıdır.`, 400);
  }

  return sayi;
}

function adresAl(deger) {
  if (bosMu(deger)) {
    throw new ApiHatasi('Teslimat adresi zorunludur.', 400);
  }

  const temiz = String(deger).trim();

  if (temiz.length < 10) {
    throw new ApiHatasi('Teslimat adresi en az 10 karakter olmalıdır.', 400);
  }

  if (temiz.length > 500) {
    throw new ApiHatasi('Teslimat adresi en fazla 500 karakter olabilir.', 400);
  }

  return temiz;
}

// ── Ödeme simülasyonu ────────────────────────────────────────────────
// Gerçek bir sistemde kart bilgisi bu sunucuya hiç uğramaz: uygulama kartı
// doğrudan ödeme kuruluşuna gönderir, bize yalnızca bir jeton döner. Burada
// ödeme kuruluşu olmadığı için ödeme taklit ediliyor. Bu yüzden değişmez
// kural şudur: kart bilgisi doğrulanır, SAKLANMAZ. Kayda yalnızca son dört
// hane ile karttaki ad yazılır; tam numara, son kullanma tarihi ve güvenlik
// kodu hiçbir yere yazılmaz ve günlüğe düşmez.

function luhnGecerli(rakamlar) {
  // Kart numarasının son hanesi, önceki hanelerden üretilen bir kontrol
  // hanesidir. Bu denetim sahteciliği değil yazım hatasını yakalar: tek bir
  // hane yanlış girildiğinde ya da iki hane yer değiştirdiğinde tutmaz.
  let toplam = 0;

  for (let i = 0; i < rakamlar.length; i += 1) {
    let hane = Number(rakamlar[rakamlar.length - 1 - i]);

    if (i % 2 === 1) {
      hane *= 2;
      if (hane > 9) hane -= 9;
    }

    toplam += hane;
  }

  return toplam % 10 === 0;
}

function kartNumarasiAl(deger) {
  if (bosMu(deger)) {
    throw new ApiHatasi('Kart numarası zorunludur.', 400);
  }

  const rakamlar = String(deger).replace(/[\s-]/g, '');

  if (!/^\d{16}$/.test(rakamlar)) {
    throw new ApiHatasi('Kart numarası 16 haneli olmalıdır.', 400);
  }

  if (!luhnGecerli(rakamlar)) {
    throw new ApiHatasi('Kart numarası geçersiz.', 400);
  }

  return rakamlar;
}

function sonKullanmaDogrula(deger) {
  if (bosMu(deger)) {
    throw new ApiHatasi('Son kullanma tarihi zorunludur.', 400);
  }

  const eslesme = /^(0[1-9]|1[0-2])\/(\d{2})$/.exec(String(deger).trim());

  if (!eslesme) {
    throw new ApiHatasi('Son kullanma tarihi AA/YY biçiminde olmalıdır.', 400);
  }

  const ay = Number(eslesme[1]);
  const yil = 2000 + Number(eslesme[2]);

  // Kart, son kullanma ayının son gününe kadar geçerlidir. Bu yüzden ayın
  // kendisiyle değil, bir sonraki ayın ilk günüyle karşılaştırılıyor.
  if (new Date(yil, ay, 1) <= new Date()) {
    throw new ApiHatasi('Kartın son kullanma tarihi geçmiş.', 400);
  }
}

function cvvDogrula(deger) {
  if (bosMu(deger)) {
    throw new ApiHatasi('Güvenlik kodu zorunludur.', 400);
  }

  if (!/^\d{3}$/.test(String(deger).trim())) {
    throw new ApiHatasi('Güvenlik kodu 3 haneli olmalıdır.', 400);
  }
}

function kartSahibiAl(deger) {
  if (bosMu(deger)) {
    throw new ApiHatasi('Kart üzerindeki ad zorunludur.', 400);
  }

  const temiz = String(deger).trim();

  if (temiz.length < 3 || temiz.length > 100) {
    throw new ApiHatasi('Kart üzerindeki ad 3-100 karakter olmalıdır.', 400);
  }

  return temiz;
}

async function olustur(kullaniciId, govde) {
  const { addressText, cardNumber, cardExpiry, cardCvv, cardHolderName } = govde;

  const adres = adresAl(addressText);

  // Ödeme bilgisi işlemden ÖNCE doğrulanıyor. Sonraya bırakılsaydı hatalı
  // bir kart yüzünden stok düşülüp geri alınması gerekirdi.
  const kartNumarasi = kartNumarasiAl(cardNumber);
  sonKullanmaDogrula(cardExpiry);
  cvvDogrula(cardCvv);
  const kartSahibi = kartSahibiAl(cardHolderName);

  // Tam numaradan bu noktadan sonra yalnızca son dört hane taşınıyor.
  const sonDortHane = kartNumarasi.slice(-4);

  return prisma.$transaction(async (tx) => {
    const sepet = await tx.cartItem.findMany({
      where: { userId: kullaniciId },
      include: { product: true },
      orderBy: { productId: 'asc' },
    });

    if (sepet.length === 0) {
      throw new ApiHatasi('Sepetiniz boş.', 400);
    }

    let toplam = new Prisma.Decimal(0);
    const kalemler = [];

    for (const satir of sepet) {
      if (!satir.product.isActive) {
        throw new ApiHatasi(
          `"${satir.product.name}" artık satışta değil. Sepetinizden çıkarın.`,
          409
        );
      }

      const dusuldu = await tx.product.updateMany({
        where: { id: satir.productId, stock: { gte: satir.quantity } },
        data: { stock: { decrement: satir.quantity } },
      });

      if (dusuldu.count === 0) {
        throw new ApiHatasi(
          `"${satir.product.name}" için yeterli stok yok.`,
          409
        );
      }

      toplam = toplam.add(satir.product.price.mul(satir.quantity));

      kalemler.push({
        productId: satir.productId,
        quantity: satir.quantity,
        unitPrice: satir.product.price,
      });
    }

    const siparis = await tx.order.create({
      data: {
        userId: kullaniciId,
        addressText: adres,
        totalAmount: toplam,

        // Ödeme taklit edildiği ve her zaman başarılı sayıldığı için sipariş
        // doğrudan ödenmiş durumda açılıyor. Gerçek bir kurulumda sipariş
        // PENDING açılır, ödeme kuruluşunun onayı gelince PAID'e geçerdi.
        status: 'PAID',
        cardLast4: sonDortHane,
        cardHolderName: kartSahibi,

        items: { create: kalemler },
      },
      include: SIPARIS_ICERIGI,
    });

    await tx.cartItem.deleteMany({ where: { userId: kullaniciId } });

    return siparis;
  });
}

async function listele(kullaniciId) {
  return prisma.order.findMany({
    where: { userId: kullaniciId },
    orderBy: { createdAt: 'desc' },
    include: SIPARIS_ICERIGI,
  });
}

async function detay(kullaniciId, siparisId) {
  const siparis = await prisma.order.findFirst({
    where: { id: siparisId, userId: kullaniciId },
    include: SIPARIS_ICERIGI,
  });

  if (!siparis) {
    throw new ApiHatasi('Sipariş bulunamadı.', 404);
  }

  return siparis;
}

async function hepsiniGetir({ status, page, limit } = {}) {
  const suzgec = {};

  if (!bosMu(status)) {
    if (!(status in DURUM_GECISLERI)) {
      throw new ApiHatasi(
        `Geçersiz durum. Seçenekler: ${Object.keys(DURUM_GECISLERI).join(', ')}.`,
        400
      );
    }
    suzgec.status = status;
  }

  const sayfa = bosMu(page) ? 1 : tamSayiAl(page, 'page');
  const istenenAdet = bosMu(limit) ? VARSAYILAN_LIMIT : tamSayiAl(limit, 'limit');
  const adet = Math.min(istenenAdet, EN_FAZLA_LIMIT);

  const [items, total] = await Promise.all([
    prisma.order.findMany({
      where: suzgec,
      orderBy: { createdAt: 'desc' },
      skip: (sayfa - 1) * adet,
      take: adet,
      include: {
        ...SIPARIS_ICERIGI,
        user: { select: { id: true, fullName: true, email: true } },
      },
    }),
    prisma.order.count({ where: suzgec }),
  ]);

  return {
    items,
    total,
    page: sayfa,
    limit: adet,
    totalPages: Math.ceil(total / adet),
  };
}

async function durumGuncelle(siparisId, { status }) {
  if (bosMu(status)) {
    throw new ApiHatasi('Yeni durum zorunludur.', 400);
  }

  if (!(status in DURUM_GECISLERI)) {
    throw new ApiHatasi(
      `Geçersiz durum. Seçenekler: ${Object.keys(DURUM_GECISLERI).join(', ')}.`,
      400
    );
  }

  const siparis = await prisma.order.findUnique({ where: { id: siparisId } });

  if (!siparis) {
    throw new ApiHatasi('Sipariş bulunamadı.', 404);
  }

  const izinliler = DURUM_GECISLERI[siparis.status];

  if (!izinliler.includes(status)) {
    throw new ApiHatasi(
      izinliler.length === 0
        ? `"${siparis.status}" durumundaki bir siparişin durumu değiştirilemez.`
        : `"${siparis.status}" durumundan "${status}" durumuna geçilemez. İzin verilenler: ${izinliler.join(', ')}.`,
      409
    );
  }

  return prisma.order.update({
    where: { id: siparisId },
    data: { status },
    include: SIPARIS_ICERIGI,
  });
}

module.exports = { olustur, listele, detay, hepsiniGetir, durumGuncelle };
