const prisma = require('../lib/prisma');
const { ApiHatasi } = require('../lib/hatalar');

const VARSAYILAN_LIMIT = 10;
const EN_FAZLA_LIMIT = 50;

const SIRALAMA_SECENEKLERI = {
  yeni: { createdAt: 'desc' },
  ucuz: { price: 'asc' },
  pahali: { price: 'desc' },
  isim: { name: 'asc' },
};

const VARSAYILAN_SIRALAMA = 'yeni';

const KATEGORI_ALANLARI = { id: true, name: true, slug: true };

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

function metinAl(deger, alanAdi, enFazla) {
  if (bosMu(deger)) {
    throw new ApiHatasi(`${alanAdi} zorunludur.`, 400);
  }

  const temiz = String(deger).trim();

  if (temiz.length > enFazla) {
    throw new ApiHatasi(`${alanAdi} en fazla ${enFazla} karakter olabilir.`, 400);
  }

  return temiz;
}

function paraAl(deger, alanAdi) {
  if (bosMu(deger)) {
    throw new ApiHatasi(`${alanAdi} zorunludur.`, 400);
  }

  const metin = String(deger).trim();

  if (!/^\d+(\.\d{1,2})?$/.test(metin)) {
    throw new ApiHatasi(
      `${alanAdi} negatif olmayan, en fazla iki ondalık basamaklı bir sayı olmalıdır.`,
      400
    );
  }

  return metin;
}

function stokAl(deger, alanAdi) {
  const sayi = Number(deger);

  if (!Number.isInteger(sayi) || sayi < 0) {
    throw new ApiHatasi(`${alanAdi} 0 veya daha büyük bir tam sayı olmalıdır.`, 400);
  }

  return sayi;
}

async function listele({ search, categoryId, sort, page, limit } = {}) {
  const suzgec = { isActive: true };

  if (!bosMu(search)) {
    suzgec.name = { contains: String(search).trim(), mode: 'insensitive' };
  }

  if (!bosMu(categoryId)) {
    suzgec.categoryId = tamSayiAl(categoryId, 'categoryId');
  }

  const sayfa = bosMu(page) ? 1 : tamSayiAl(page, 'page');
  const istenenAdet = bosMu(limit) ? VARSAYILAN_LIMIT : tamSayiAl(limit, 'limit');
  const adet = Math.min(istenenAdet, EN_FAZLA_LIMIT);

  if (!bosMu(sort) && !(sort in SIRALAMA_SECENEKLERI)) {
    throw new ApiHatasi(
      `Geçersiz sıralama. Seçenekler: ${Object.keys(SIRALAMA_SECENEKLERI).join(', ')}.`,
      400
    );
  }

  const siralama = SIRALAMA_SECENEKLERI[bosMu(sort) ? VARSAYILAN_SIRALAMA : sort];

  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where: suzgec,
      orderBy: siralama,
      skip: (sayfa - 1) * adet,
      take: adet,
      include: { category: { select: KATEGORI_ALANLARI } },
    }),
    prisma.product.count({ where: suzgec }),
  ]);

  return {
    items,
    total,
    page: sayfa,
    limit: adet,
    totalPages: Math.ceil(total / adet),
  };
}

async function idIleGetir(id) {
  const urun = await prisma.product.findFirst({
    where: { id, isActive: true },
    include: { category: { select: KATEGORI_ALANLARI } },
  });

  if (!urun) {
    throw new ApiHatasi('Ürün bulunamadı.', 404);
  }

  return urun;
}

async function kategoriDogrula(categoryId) {
  const kategoriId = tamSayiAl(categoryId, 'categoryId');

  const kategori = await prisma.category.findUnique({ where: { id: kategoriId } });

  if (!kategori) {
    throw new ApiHatasi('Belirtilen kategori bulunamadı.', 400);
  }

  return kategoriId;
}

async function olustur({ name, description, price, stock, imageUrl, categoryId }) {
  const kategoriId = await kategoriDogrula(categoryId);

  return prisma.product.create({
    data: {
      name: metinAl(name, 'Ürün adı', 200),
      description: metinAl(description, 'Açıklama', 2000),
      price: paraAl(price, 'Fiyat'),
      stock: bosMu(stock) ? 0 : stokAl(stock, 'Stok'),
      imageUrl: bosMu(imageUrl) ? null : String(imageUrl).trim(),
      categoryId: kategoriId,
    },
    include: { category: { select: KATEGORI_ALANLARI } },
  });
}

async function guncelle(id, { name, description, price, stock, imageUrl, categoryId }) {
  await idIleGetir(id);

  const veri = {};

  if (name !== undefined) veri.name = metinAl(name, 'Ürün adı', 200);
  if (description !== undefined) veri.description = metinAl(description, 'Açıklama', 2000);
  if (price !== undefined) veri.price = paraAl(price, 'Fiyat');
  if (stock !== undefined) veri.stock = stokAl(stock, 'Stok');
  if (imageUrl !== undefined) veri.imageUrl = bosMu(imageUrl) ? null : String(imageUrl).trim();
  if (categoryId !== undefined) veri.categoryId = await kategoriDogrula(categoryId);

  if (Object.keys(veri).length === 0) {
    throw new ApiHatasi('Güncellenecek alan gönderilmedi.', 400);
  }

  return prisma.product.update({
    where: { id },
    data: veri,
    include: { category: { select: KATEGORI_ALANLARI } },
  });
}

async function sil(id) {
  await idIleGetir(id);

  await prisma.product.update({
    where: { id },
    data: { isActive: false },
  });
}

module.exports = { listele, idIleGetir, olustur, guncelle, sil };
