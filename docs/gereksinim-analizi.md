# Gereksinim Analizi

**Proje:** İSKİ E-Ticaret Mobil Uygulaması
**Hazırlayan:** Mert CEREN
**Tarih:** 19/08/2026 (Staj Gün 3)

---

## 1. Amaç

Kullanıcıların ürünleri arayıp inceleyebildiği, sepete ekleyip sipariş
verebildiği; bir yöneticinin ürün, kategori, stok ve siparişleri yönettiği
mobil bir e-ticaret uygulaması geliştirmek. Kullanıcılar, roller, kategoriler
ve ürünler ilişkisel bir veritabanında tutulur.

## 2. Aktörler

| Aktör | Tanım | Kimlik kaynağı |
|---|---|---|
| Ziyaretçi | Giriş yapmamış kullanıcı | — (anonim) |
| Kullanıcı | Kayıtlı ve giriş yapmış kişi | `User.role = USER` |
| Admin | Yönetim yetkisi olan kullanıcı | `User.role = ADMIN` |

**Karar 1 — Ziyaretçi ürünleri görebilir.** Ürün listeleme, arama ve detay
görüntüleme giriş gerektirmez. Sepet ve sipariş işlemleri giriş gerektirir.
*Gerekçe:* Kullanıcıyı ürünü görmeden kayıt olmaya zorlamak dönüşümü düşürür.
Teknik karşılığı: okuma uçları herkese açık, geri kalanı token ister.

**Karar 2 — Admin ayrı tablo değil, `User` üzerinde bir alandır.**
*Gerekçe:* Admin de bir kullanıcıdır; e-posta, parola ve oturum mekanizması
aynıdır. Ayrı tablo, giriş mantığının iki yerde yazılmasını gerektirirdi.

## 3. Fonksiyonel Gereksinimler (Use-Case'ler)

### 3.1 Ziyaretçi

| No | Use-case |
|---|---|
| UC-01 | Ürünleri sayfalı olarak listeler |
| UC-02 | Ürün adına göre arama yapar |
| UC-03 | Kategoriye göre filtreler |
| UC-04 | Fiyata göre sıralar |
| UC-05 | Ürün detayını görüntüler |
| UC-06 | Kayıt olur |
| UC-07 | Giriş yapar |

### 3.2 Kullanıcı (UC-01…UC-05 dahil)

| No | Use-case |
|---|---|
| UC-08 | Uygulama açılışında oturumu otomatik sürdürür |
| UC-09 | Çıkış yapar |
| UC-10 | Ürünü favorilere ekler / çıkarır |
| UC-11 | Favorilerini listeler |
| UC-12 | Sepete ürün ekler |
| UC-13 | Sepetteki ürün adedini değiştirir |
| UC-14 | Sepetten ürün çıkarır |
| UC-15 | Sepeti ve toplam tutarı görüntüler |
| UC-16 | Sepetten sipariş oluşturur |
| UC-17 | Kendi siparişlerini listeler |
| UC-18 | Sipariş detayını görüntüler |
| UC-19 | Profilini görüntüler |

### 3.3 Admin (UC-01…UC-09 dahil)

| No | Use-case |
|---|---|
| UC-20 | Kategori ekler / günceller / siler |
| UC-21 | Ürün ekler |
| UC-22 | Ürün günceller |
| UC-23 | Ürün siler |
| UC-24 | Ürün görseli yükler |
| UC-25 | Stok günceller |
| UC-26 | Tüm siparişleri listeler ve filtreler |
| UC-27 | Sipariş durumunu günceller |

### 3.4 Genişletme (Gün 16–17)

| No | Use-case |
|---|---|
| UC-28 | Satın alınan ürüne puan ve yorum bırakır |
| UC-29 | Adres defterini yönetir |

## 4. Fonksiyonel Olmayan Gereksinimler

| No | Gereksinim | Nasıl doğrulanır |
|---|---|---|
| NFR-01 | Parolalar `bcrypt` ile hash'lenir, hiçbir koşulda düz metin saklanmaz | Veritabanında `passwordHash` alanı okunur |
| NFR-02 | Korumalı uçlar JWT ile doğrulanır; admin uçları ayrıca rol kontrolünden geçer | Token'sız istek 401, yetkisiz kullanıcı 403 alır |
| NFR-03 | Sipariş oluşturma tek bir transaction içinde yürür; kısmî yazma oluşmaz | Stok yetersizken sipariş reddedilir ve stok değişmez |
| NFR-04 | Ürün listeleme sayfalanır; tüm kayıtlar tek istekte dönmez | `page` / `limit` parametreleri ile doğrulanır |
| NFR-05 | Bir kullanıcı yalnızca kendi sepetine, siparişine ve favorilerine erişebilir | Başka kullanıcının kaydına erişim denemesi reddedilir |
| NFR-06 | Kart bilgisi hiçbir katmanda saklanmaz, gönderilmez, loglanmaz; yalnızca son 4 hane tutulur | Veritabanı ve log incelenir |
| NFR-07 | Her ekran yükleniyor / boş / hata durumlarını ayrı ayrı ele alır | Backend kapalıyken anlamlı hata ekranı görünür |
| NFR-08 | Backend katmanlı yazılır (route → controller → service → veri); `flutter analyze` uyarısız | Kod incelemesi ve `flutter analyze` |

## 5. Kapsam Dışı

Ödeme entegrasyonu (gerçek tahsilat), kargo takibi, iade akışı, kupon sistemi.

*Not:* Gün 12'de bir **ödeme simülasyon ekranı** yapılacaktır. Kart formu ve
doğrulama gerçek olacak, ancak tahsilat yapılmayacak ve kart bilgisi
saklanmayacaktır.

## 6. Veri Modeli

Bkz. [er-diagram.md](er-diagram.md) — 7 tablo, 8 ilişki.