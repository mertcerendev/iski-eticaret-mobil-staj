const prisma = require('../lib/prisma');
const { ApiHatasi } = require('../lib/hatalar');

const TURKCE_HARFLER = { ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u' };

function slugUret(ad) {
  return ad
    .trim()
    .toLowerCase()
    .replace(/[çğıöşü]/g, (harf) => TURKCE_HARFLER[harf])
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function hepsiniGetir() {
  return prisma.category.findMany({ orderBy: { name: 'asc' } });
}

async function idIleGetir(id) {
  const kategori = await prisma.category.findUnique({ where: { id } });

  if (!kategori) {
    throw new ApiHatasi('Kategori bulunamadı.', 404);
  }

  return kategori;
}

async function olustur({ name, imageUrl }) {
  if (!name || !name.trim()) {
    throw new ApiHatasi('Kategori adı zorunludur.', 400);
  }

  const temizAd = name.trim();
  const slug = slugUret(temizAd);

  const mevcut = await prisma.category.findFirst({
    where: { OR: [{ name: temizAd }, { slug }] },
  });

  if (mevcut) {
    throw new ApiHatasi('Bu kategori zaten mevcut.', 409);
  }

  return prisma.category.create({
    data: { name: temizAd, slug, imageUrl: imageUrl ?? null },
  });
}

async function guncelle(id, { name, imageUrl }) {
  await idIleGetir(id);

  const veri = {};

  if (name !== undefined) {
    if (!name.trim()) {
      throw new ApiHatasi('Kategori adı boş olamaz.', 400);
    }
    veri.name = name.trim();
    veri.slug = slugUret(veri.name);

    const cakisan = await prisma.category.findFirst({
      where: { OR: [{ name: veri.name }, { slug: veri.slug }], NOT: { id } },
    });

    if (cakisan) {
      throw new ApiHatasi('Bu kategori adı zaten kullanılıyor.', 409);
    }
  }

  if (imageUrl !== undefined) {
    veri.imageUrl = imageUrl;
  }

  if (Object.keys(veri).length === 0) {
    throw new ApiHatasi('Güncellenecek alan gönderilmedi.', 400);
  }

  return prisma.category.update({ where: { id }, data: veri });
}

async function sil(id) {
  await idIleGetir(id);

  const urunSayisi = await prisma.product.count({ where: { categoryId: id } });

  if (urunSayisi > 0) {
    throw new ApiHatasi(
      `Bu kategoriye bağlı ${urunSayisi} ürün var. Önce ürünleri başka kategoriye taşıyın.`,
      409
    );
  }

  await prisma.category.delete({ where: { id } });
}

module.exports = { hepsiniGetir, idIleGetir, olustur, guncelle, sil };