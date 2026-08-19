require('dotenv/config');

const bcrypt = require('bcryptjs');
const prisma = require('../src/lib/prisma');

const kategoriler = [
  { name: 'Elektronik',  slug: 'elektronik'  },
  { name: 'Ev Aletleri', slug: 'ev-aletleri' },
  { name: 'Giyim',       slug: 'giyim'       },
  { name: 'Kitap',       slug: 'kitap'       },
  { name: 'Spor',        slug: 'spor'        },
];

const urunler = [
  { name: 'Kablosuz Kulaklık', price: '1499.90', stock: 25, kategoriSlug: 'elektronik',
    description: 'Aktif gürültü engelleme özellikli, 30 saat pil ömürlü kulak üstü kulaklık.' },
  { name: 'Mekanik Klavye', price: '899.90', stock: 0, kategoriSlug: 'elektronik',
    description: 'Mavi switch, RGB aydınlatma, Türkçe Q düzen.' },
  { name: 'Akıllı Saat', price: '2299.00', stock: 3, kategoriSlug: 'elektronik',
    description: 'Nabız ve uyku takibi, 7 gün pil ömrü, suya dayanıklı.' },

  { name: 'Kahve Makinesi', price: '3499.00', stock: 7, kategoriSlug: 'ev-aletleri',
    description: 'Otomatik öğütücülü espresso makinesi, 15 bar basınç.' },
  { name: 'Su Isıtıcısı', price: '649.90', stock: 12, kategoriSlug: 'ev-aletleri',
    description: '1.7 litre paslanmaz çelik, otomatik kapanma.' },
  { name: 'Robot Süpürge', price: '5999.00', stock: 4, kategoriSlug: 'ev-aletleri',
    description: 'Lazer haritalama, 120 dakika çalışma süresi.' },

  { name: 'Pamuklu Tişört', price: '249.90', stock: 60, kategoriSlug: 'giyim',
    description: '%100 pamuk, bisiklet yaka, ön yıkamalı.' },
  { name: 'Kot Pantolon', price: '799.90', stock: 18, kategoriSlug: 'giyim',
    description: 'Slim fit, esnek denim kumaş.' },
  { name: 'Spor Ayakkabı', price: '1899.00', stock: 9, kategoriSlug: 'giyim',
    description: 'Hafif taban, nefes alan örgü üst yüzey.' },

  { name: 'Temiz Kod', price: '320.00', stock: 30, kategoriSlug: 'kitap',
    description: 'Yazılım geliştirmede okunabilirlik ve bakım kolaylığı üzerine.' },
  { name: 'Yazılım Mimarisi', price: '410.00', stock: 15, kategoriSlug: 'kitap',
    description: 'Katmanlı mimari, bağımlılık yönetimi ve tasarım kararları.' },
  { name: 'Veri Yapıları ve Algoritmalar', price: '385.00', stock: 22, kategoriSlug: 'kitap',
    description: 'Temel veri yapıları, karmaşıklık analizi ve örnek uygulamalar.' },

  { name: 'Yoga Matı', price: '459.90', stock: 40, kategoriSlug: 'spor',
    description: '6 mm kalınlık, kaymaz yüzey, taşıma askısı dahil.' },
  { name: 'Dambıl Seti', price: '1250.00', stock: 6, kategoriSlug: 'spor',
    description: 'Ayarlanabilir ağırlık, 2 x 20 kg, kauçuk kaplama.' },
  { name: 'Koşu Bandı', price: '12750.00', stock: 2, kategoriSlug: 'spor',
    description: 'Katlanabilir gövde, 16 km/s hız, eğim ayarı.' },
];

async function main() {
  const parolaHash = await bcrypt.hash('Admin123!', 10);

  const admin = await prisma.user.upsert({
    where:  { email: 'admin@eticaret.com' },
    update: {},
    create: {
      email:        'admin@eticaret.com',
      passwordHash: parolaHash,
      fullName:     'Sistem Yöneticisi',
      role:         'ADMIN',
    },
  });
  console.log(`Admin hazır: ${admin.email}`);

  for (const kategori of kategoriler) {
    await prisma.category.upsert({
      where:  { slug: kategori.slug },
      update: {},
      create: kategori,
    });
  }
  console.log(`${kategoriler.length} kategori hazır.`);

  let eklenen = 0;

  for (const urun of urunler) {
    const { kategoriSlug, ...alanlar } = urun;

    const mevcut = await prisma.product.findFirst({ where: { name: alanlar.name } });
    if (mevcut) continue;

    const kategori = await prisma.category.findUnique({ where: { slug: kategoriSlug } });

    await prisma.product.create({
      data: { ...alanlar, categoryId: kategori.id },
    });
    eklenen++;
  }
  console.log(`${eklenen} ürün eklendi (toplam ${urunler.length}).`);
}

main()
  .catch((hata) => {
    console.error('Seed başarısız:', hata);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });