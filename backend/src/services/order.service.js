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

async function olustur(kullaniciId, { addressText }) {
  const adres = adresAl(addressText);

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
