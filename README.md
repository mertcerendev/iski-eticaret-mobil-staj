# Nuvia — Mobil E-Ticaret Uygulaması

İSKİ Yazılım Şube Müdürlüğü staj projesi (17/08/2026 – 11/09/2026, 20 iş günü).

Ürün kataloğu, sepet, favoriler, sipariş ve ödeme simülasyonu içeren, uçtan uca
çalışan bir e-ticaret uygulaması. Sunucu Node.js/Express, veritabanı PostgreSQL,
mobil uygulama Flutter ile yazıldı.

---

## İçindekiler

- [Ne yapıyor](#ne-yapıyor)
- [Teknolojiler](#teknolojiler)
- [Mimari](#mimari)
- [Kurulum](#kurulum)
- [Çalıştırma](#çalıştırma)
- [Deneme hesabı](#deneme-hesabı)
- [Klasör yapısı](#klasör-yapısı)
- [Test](#test)
- [Bilinen konular](#bilinen-konular)

---

## Ne yapıyor

**Kullanıcı**

- Kayıt ve giriş; uygulama kapatılıp açıldığında oturum korunur
- Ürün kataloğu: arama, kategoriye göre süzme, dört seçenekli sıralama, sonsuz kaydırma
- Ürün detayı, favorilere ekleme
- Sepet: ekleme, adet güncelleme, çıkarma, canlı toplam
- Sipariş verme + ödeme simülasyonu (kart doğrulaması)
- Sipariş geçmişi ve sipariş ayrıntısı
- Profil düzenleme ve parola değiştirme

**Yönetici** (rolü `ADMIN` olan kullanıcı)

- Ürün ekleme, düzenleme, satıştan kaldırma
- Ürün görseli yükleme
- Bütün siparişleri görüntüleme, duruma göre süzme
- Sipariş durumunu ilerletme (geçiş tablosuna uygun olarak)

---

## Teknolojiler

### Sunucu (`backend/`)

| Paket | Görevi |
|---|---|
| Express 5 | Web sunucusu çatısı; async hataları otomatik iletir |
| Prisma 7 | Veritabanı erişim katmanı (ORM) |
| `@prisma/adapter-pg` + `pg` | Prisma 7 kendi motorunu kaldırdı; sürücü bağdaştırıcısı zorunlu |
| PostgreSQL 16 | Veritabanı (Docker konteynerinde, **port 5433**) |
| bcryptjs | Parola özetleme |
| jsonwebtoken | Oturum belirteci (JWT) |
| multer | Görsel yükleme (`multipart/form-data`) |
| cors, morgan, dotenv | Kaynak izni, istek günlüğü, ortam değişkenleri |

### Mobil (`mobile/`)

| Paket | Görevi |
|---|---|
| Flutter / Dart | Arayüz çatısı ve dil |
| dio | HTTP istemcisi; **interceptor** desteği için seçildi |
| provider | Durum yönetimi |
| flutter_secure_storage | Belirteci Android Keystore / iOS Keychain içinde saklar |
| cached_network_image | Görselleri önbelleğe alır |
| image_picker | Yönetici ürün görseli seçimi |

---

## Mimari

Her iki taraf da katmanlı. Kural: **her katman yalnızca bir alttakini tanır.**

```
        MOBİL                              SUNUCU
┌────────────────────┐             ┌────────────────────┐
│  screens/          │             │  routes/           │ adres eşlemesi
│  (ne görünüyor)    │             ├────────────────────┤
├────────────────────┤             │  middleware/       │ kimlik, yetki, hata
│  providers/        │  hafıza     ├────────────────────┤
│  (ne biliniyor)    │             │  controllers/      │ istek → servis
├────────────────────┤             ├────────────────────┤
│  services/         │  ── HTTP ──►│  services/         │ iş kuralları
│  (nasıl sorulur)   │             ├────────────────────┤
├────────────────────┤             │  lib/prisma        │ veritabanı
│  core/network      │             └────────────────────┘
│  (tek Dio + token) │                       │
└────────────────────┘                  PostgreSQL
```

Öne çıkan kararlar:

- **Para `Decimal` ile tutulur.** JSON'a metin olarak gider; mobil taraf yalnızca
  gösterim için ondalıklı sayıya çevirir. Bütün hesap sunucuda kalır.
- **Sipariş anındaki fiyat dondurulur** (`OrderItem.unitPrice`). Ürün sonradan
  zamlansa bile geçmiş sipariş değişmez.
- **Stok düşümü yarışa karşı korumalı:** kontrol ve düşme tek SQL cümlesinde
  (`updateMany` + `stock: { gte: adet }`). İki kişi son ürünü aynı anda alamaz.
- **Ürün silme = pasife alma.** Geçmiş siparişler ürüne bağlı olduğu için
  gerçek silme veritabanı kısıtına takılır.
- **Kart bilgisi doğrulanır, saklanmaz.** Yalnızca son dört hane ve karttaki ad
  kaydedilir.
- **Belirteç tek yerden eklenir.** Giden her istek Dio interceptor'ından geçer;
  servisler belirteçten habersizdir.

---

## Kurulum

### Gereksinimler

- Node.js 20+
- Docker Desktop
- Flutter 3.44+ (Dart 3.12+)
- Android Studio + bir Android öykünücüsü (Pixel 8 önerilir)

### 1. Veritabanını başlat

```bash
docker compose up -d
```

PostgreSQL 16 `iski_eticaret_db` adıyla **5433** portunda çalışır. (5432 değil:
geliştirme makinesinde o port başka bir proje tarafından kullanılıyordu.)

### 2. Sunucuyu hazırla

```bash
cd backend
npm install
cp .env.example .env
```

`.env` dosyasını doldur:

```
DATABASE_URL="postgresql://KULLANICI:PAROLA@localhost:5433/VERITABANI?schema=public"
PORT=3000
JWT_SECRET=rastgele-uretilmis-64-karakterlik-dizge
JWT_EXPIRES_IN=7d
```

Veritabanı şemasını kur ve başlangıç verisini yükle:

```bash
npx prisma migrate deploy
node prisma/seed.js
```

Seed betiği 1 yönetici, 5 kategori ve 15 ürün oluşturur.

### 3. Mobil uygulamayı hazırla

```bash
cd mobile
flutter pub get
```

---

## Çalıştırma

```bash
# 1. Veritabanı
docker compose up -d

# 2. Sunucu (backend/ içinde)
npm run dev

# 3. Öykünücü
flutter emulators --launch Pixel_8

# 4. Uygulama (mobile/ içinde)
flutter run
```

Sunucunun ayakta olduğu şununla doğrulanır:

```bash
curl http://localhost:3000/api/health
```

> **Not:** Öykünücü, geliştirme bilgisayarına `10.0.2.2` adresinden ulaşır.
> Kendi `localhost`'u öykünücünün kendisidir. Adres
> `mobile/lib/core/constants/api_constants.dart` içinde tanımlı.

---

## Deneme hesapları

Uygulama giriş istemeden açılıyor: ürünler, kategoriler ve arama misafir
olarak kullanılabiliyor. Sepet, favoriler ve siparişler hesaba bağlı —
bunlara dokunulduğunda giriş ekranı açılıyor.

| Rol | E-posta | Parola |
|---|---|---|
| Yönetici | `admin@eticaret.com` | `Admin123!` |
| Müşteri | `musteri@nuvia.com` | `Musteri123!` |

İkisi de `prisma/seed.js` tarafından oluşturuluyor. Yönetici bölümleri
(ürün ekleme, sipariş yönetimi) yalnızca birincisinde görünür; ikisi arasında
geçiş yapılarak rol denetimi gösterilebilir.

---

## Klasör yapısı

```
.
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma        7 tablo, ilişkiler ve enum'lar
│   │   ├── migrations/          tabloları kuran SQL
│   │   └── seed.js              başlangıç verisi
│   └── src/
│       ├── routes/              adres → denetleyici eşlemesi
│       ├── middleware/          kimlik, yönetici denetimi, yükleme, hata
│       ├── controllers/         isteği alır, servise verir
│       ├── services/            bütün iş kuralları
│       ├── lib/                 prisma, token, hata sınıfları
│       └── index.js             sunucu açılışı
│
├── mobile/
│   ├── lib/
│   │   ├── core/                adresler, HTTP istemcisi, tema, doğrulayıcılar
│   │   ├── models/              JSON → nesne dönüşümü
│   │   ├── services/            sunucu çağrıları (durum tutmaz)
│   │   ├── providers/           uygulamanın hafızası
│   │   ├── screens/             ekranlar
│   │   ├── widgets/             birden çok ekranda kullanılan parçalar
│   │   └── main.dart            sağlayıcıların kurulumu, oturum kapısı
│   └── test/                    birim ve bileşen testleri
│
├── docs/
│   ├── api.md                   uçların tam listesi ve gerekçeleri
│   ├── gereksinim-analizi.md    aktörler ve kullanım senaryoları
│   └── er-diagram.md            veri modeli
│
└── docker-compose.yml
```

---

## Test

```bash
cd mobile
flutter analyze     # statik çözümleme
flutter test        # birim ve bileşen testleri
```

Testler ağa çıkmayan parçaları kapsar: model dönüşümleri, doğrulayıcılar, kart
biçimlendiricileri, sipariş durum geçiş tablosu ve ürün kartı bileşeni.

Sunucu uçları geliştirme sırasında `curl` ile senaryo senaryo denendi;
ayrıntıları `docs/api.md` içinde.

---

## Bilinen konular

**`npm audit` — 4 yüksek uyarı (kabul edildi)**

Kalan uyarılar `deepmerge-ts` ve `mysql2` paketlerinden geliyor. İkisi de
Prisma'nın **komut satırı aracının** bağımlılığı; çalışan sunucuya dâhil
değiller ve MySQL sürücüsü bu projede hiç kullanılmıyor.

`npm audit fix --force` bunları Prisma'yı 6.19.3'e **düşürerek** çözmeyi
öneriyor. Proje Prisma 7'nin sürücü bağdaştırıcısı üzerine kurulu olduğu için
bu geri alma kabul edilmedi. Kırıcı olmayan `npm audit fix` uygulandı ve uyarı
sayısı 6'dan 4'e indi.

**`flutter_secure_storage` 9.2.4'e sabitlendi**

11.x sürümü Android `compileSdk 37` istiyor; projede 36 var (AGP 9.0.1 üst
sınırı). Sürüm sabitlendi, derleme sorunsuz.

**Ödeme bir simülasyondur**

Gerçek tahsilat yapılmaz. Gerçek bir kurulumda kart bilgisi bu sunucuya hiç
uğramaz; uygulama kartı doğrudan ödeme kuruluşuna gönderir ve sunucuya yalnızca
bir jeton iletilir. Burada ödeme kuruluşu bulunmadığı için akış taklit ediliyor —
ancak "kart doğrulanır, saklanmaz" kuralı korunuyor.

**İptal edilen sipariş stoğu geri yüklemez**

Sipariş `CANCELLED` durumuna alındığında düşülen stok geri eklenmiyor. Gerçek
bir sistemde bu bir iade akışı gerektirir; bu projenin kapsamı dışında bırakıldı.
