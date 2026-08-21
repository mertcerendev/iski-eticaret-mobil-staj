const { Prisma } = require('@prisma/client');

const prisma = require('../lib/prisma');
const { ApiHatasi } = require('../lib/hatalar');

const EN_FAZLA_ADET = 20;

const URUN_ALANLARI = {
  id: true,
  name: true,
  price: true,
  stock: true,
  imageUrl: true,
  isActive: true,
};

function tamSayiAl(deger, alanAdi) {
  const sayi = Number(deger);

  if (!Number.isInteger(sayi) || sayi < 1) {
    throw new ApiHatasi(`${alanAdi} 1 veya daha büyük bir tam sayı olmalıdır.`, 400);
  }

  return sayi;
}

function adetAl(deger) {
  const adet = tamSayiAl(deger, 'Adet');

  if (adet > EN_FAZLA_ADET) {
    throw new ApiHatasi(`Bir üründen en fazla ${EN_FAZLA_ADET} adet alınabilir.`, 400);
  }

  return adet;
}

async function satilabilirUrunGetir(urunId, adet) {
  const urun = await prisma.product.findFirst({
    where: { id: urunId, isActive: true },
  });

  if (!urun) {
    throw new ApiHatasi('Ürün bulunamadı.', 404);
  }

  if (urun.stock < adet) {
    throw new ApiHatasi(
      `Yetersiz stok. Bu üründen en fazla ${urun.stock} adet eklenebilir.`,
      409
    );
  }

  return urun;
}

function sepetYaniti(satirlar) {
  let toplam = new Prisma.Decimal(0);

  const items = satirlar.map((satir) => {
    const satinAlinabilir = satir.product.isActive && satir.product.stock >= satir.quantity;
    const araToplam = satir.product.price.mul(satir.quantity);

    if (satinAlinabilir) {
      toplam = toplam.add(araToplam);
    }

    return {
      id: satir.id,
      productId: satir.productId,
      quantity: satir.quantity,
      product: satir.product,
      subtotal: araToplam.toFixed(2),
      satinAlinabilir,
    };
  });

  return {
    items,
    totalAmount: toplam.toFixed(2),
    itemCount: items.length,
    totalQuantity: items.reduce((t, s) => t + s.quantity, 0),
  };
}

async function listele(kullaniciId) {
  const satirlar = await prisma.cartItem.findMany({
    where: { userId: kullaniciId },
    orderBy: { createdAt: 'asc' },
    include: { product: { select: URUN_ALANLARI } },
  });

  return sepetYaniti(satirlar);
}

async function ekle(kullaniciId, { productId, quantity }) {
  const urunId = tamSayiAl(productId, 'productId');
  const adet = quantity === undefined ? 1 : adetAl(quantity);

  const mevcut = await prisma.cartItem.findUnique({
    where: { userId_productId: { userId: kullaniciId, productId: urunId } },
  });

  const yeniAdet = mevcut ? mevcut.quantity + adet : adet;

  if (yeniAdet > EN_FAZLA_ADET) {
    throw new ApiHatasi(
      `Sepette bu üründen ${mevcut.quantity} adet var. Toplam ${EN_FAZLA_ADET} adedi aşamaz.`,
      400
    );
  }

  await satilabilirUrunGetir(urunId, yeniAdet);

  await prisma.cartItem.upsert({
    where: { userId_productId: { userId: kullaniciId, productId: urunId } },
    update: { quantity: yeniAdet },
    create: { userId: kullaniciId, productId: urunId, quantity: yeniAdet },
  });

  return listele(kullaniciId);
}

async function adetGuncelle(kullaniciId, urunId, { quantity }) {
  const adet = adetAl(quantity);

  const mevcut = await prisma.cartItem.findUnique({
    where: { userId_productId: { userId: kullaniciId, productId: urunId } },
  });

  if (!mevcut) {
    throw new ApiHatasi('Bu ürün sepetinizde bulunmuyor.', 404);
  }

  await satilabilirUrunGetir(urunId, adet);

  await prisma.cartItem.update({
    where: { userId_productId: { userId: kullaniciId, productId: urunId } },
    data: { quantity: adet },
  });

  return listele(kullaniciId);
}

async function cikar(kullaniciId, urunId) {
  const silinen = await prisma.cartItem.deleteMany({
    where: { userId: kullaniciId, productId: urunId },
  });

  if (silinen.count === 0) {
    throw new ApiHatasi('Bu ürün sepetinizde bulunmuyor.', 404);
  }

  return listele(kullaniciId);
}

async function temizle(kullaniciId) {
  await prisma.cartItem.deleteMany({ where: { userId: kullaniciId } });

  return listele(kullaniciId);
}

module.exports = { listele, ekle, adetGuncelle, cikar, temizle };
