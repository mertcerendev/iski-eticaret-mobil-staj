const prisma = require('../lib/prisma');
const { ApiHatasi } = require('../lib/hatalar');

const URUN_ALANLARI = {
  id: true,
  name: true,
  price: true,
  stock: true,
  imageUrl: true,
  isActive: true,
};

async function listele(kullaniciId) {
  const satirlar = await prisma.favorite.findMany({
    where: { userId: kullaniciId },
    orderBy: { createdAt: 'desc' },
    include: { product: { select: URUN_ALANLARI } },
  });

  return satirlar.map((satir) => ({
    id: satir.id,
    productId: satir.productId,
    product: satir.product,
  }));
}

async function degistir(kullaniciId, urunId) {
  const urun = await prisma.product.findFirst({
    where: { id: urunId, isActive: true },
  });

  if (!urun) {
    throw new ApiHatasi('Ürün bulunamadı.', 404);
  }

  const anahtar = { userId_productId: { userId: kullaniciId, productId: urunId } };
  const mevcut = await prisma.favorite.findUnique({ where: anahtar });

  if (mevcut) {
    await prisma.favorite.delete({ where: anahtar });
    return { productId: urunId, favorited: false };
  }

  await prisma.favorite.create({ data: { userId: kullaniciId, productId: urunId } });
  return { productId: urunId, favorited: true };
}

module.exports = { listele, degistir };
