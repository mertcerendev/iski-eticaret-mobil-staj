# E-Ticaret API Referansı

**Sunucu:** `http://localhost:3000`
**Emulator'den:** `http://10.0.2.2:3000` (Gün 8'de mobil taraf bunu kullanacak)

Toplam **27 uç**.

---

## Erişim seviyeleri

| İşaret | Anlamı | Nasıl çalışır |
|---|---|---|
| **Herkes** | Giriş gerekmez | Ara katman yok |
| **Girişli** | Geçerli belirteç şart | `auth` ara katmanı |
| **Yönetici** | Belirteç + `role = ADMIN` | `auth` sonra `requireAdmin` |

Belirteç her istekte şu başlıkla gönderilir:

```
Authorization: Bearer <token>
```

`auth` geçemezse **401**, `requireAdmin` geçemezse **403** döner.

---

## Durum kodları

| Kod | Ne zaman |
|---|---|
| 200 | Başarılı okuma / güncelleme |
| 201 | Yeni kayıt oluşturuldu |
| 204 | Başarılı, gönderilecek içerik yok (silme) |
| 400 | Gönderilen veri hatalı (doğrulama) |
| 401 | Kimlik sunulmadı veya belirteç geçersiz |
| 403 | Kimlik geçerli ama yetki yetersiz |
| 404 | Kayıt yok — **veya sana ait değil** |
| 409 | İstek geçerli ama mevcut duruma aykırı (stok, çakışma) |
| 500 | Beklenmeyen sunucu hatası |

Hata yanıtlarının tamamı aynı biçimde:

```json
{ "message": "Açıklayıcı mesaj" }
```

---

## 1. Sağlık

| Yöntem | Adres | Erişim |
|---|---|---|
| GET | `/api/health` | Herkes |

Veritabanına hiç dokunmaz — sunucunun ayakta olup olmadığını söyler.

```json
{ "status": "ok", "time": "2026-08-21T11:37:04.743Z" }
```

---

## 2. Kimlik — `/api/auth`

| Yöntem | Adres | Erişim | Ne yapar |
|---|---|---|---|
| POST | `/register` | Herkes | Kayıt olur, belirteç döner |
| POST | `/login` | Herkes | Giriş yapar, belirteç döner |
| GET | `/me` | Girişli | Kendi profilini döner |

### POST /api/auth/register

```json
{ "email": "ali@ornek.com", "password": "Sifre1234", "fullName": "Ali Veli" }
```

- Parola en az 8 karakter
- E-posta biçim denetiminden geçer, küçük harfe çevrilir
- `role` gövdeden **okunmaz** — herkes `USER` olarak açılır (yetki yükseltme önlemi)

Yanıt `201`:

```json
{
  "user": { "id": 4, "email": "ali@ornek.com", "fullName": "Ali Veli", "role": "USER" },
  "token": "eyJhbGciOi..."
}
```

`passwordHash` yanıtta **asla** yer almaz.

### POST /api/auth/login

`{ "email": ..., "password": ... }`

Kullanıcı bulunamazsa da parola yanlışsa da **aynı mesaj** döner: `E-posta veya parola hatalı.` Farklı mesaj verilseydi sistemde kayıtlı e-postalar dışarıdan tespit edilebilirdi.

---

## 3. Kategori — `/api/categories`

| Yöntem | Adres | Erişim | Ne yapar |
|---|---|---|---|
| GET | `/` | Herkes | Tüm kategoriler (isme göre) |
| GET | `/:id` | Herkes | Tek kategori |
| POST | `/` | Yönetici | Yeni kategori |
| PUT | `/:id` | Yönetici | Kısmi güncelleme |
| DELETE | `/:id` | Yönetici | Siler |

**POST** gövdesi: `{ "name": "Oyuncak", "imageUrl": null }`

- `slug` isimden **üretilir** (`Oyuncak` → `oyuncak`), dışarıdan alınmaz
- Aynı isim veya slug varsa **409**

**DELETE** — kategoriye bağlı ürün varsa **409**. Veritabanı bu kısıtı zaten uygular, ancak ürettiği teknik mesaj kullanıcıya gösterilemeyeceği için denetim uygulama katmanında da yapılır.

---

## 4. Ürün — `/api/products`

| Yöntem | Adres | Erişim | Ne yapar |
|---|---|---|---|
| GET | `/` | Herkes | Arama + filtre + sıralama + sayfalama |
| GET | `/:id` | Herkes | Ürün detayı |
| POST | `/` | Yönetici | Yeni ürün |
| PUT | `/:id` | Yönetici | Kısmi güncelleme |
| DELETE | `/:id` | Yönetici | **Pasife alır** (gerçek silme değil) |

### GET /api/products — sorgu parametreleri

| Parametre | Örnek | Varsayılan | Notlar |
|---|---|---|---|
| `search` | `kulak` | yok | Ürün adında geçer mi; büyük/küçük harf farketmez |
| `categoryId` | `2` | yok | Tam eşleşme |
| `sort` | `ucuz` | `yeni` | **Beyaz liste:** `yeni`, `ucuz`, `pahali`, `isim` |
| `page` | `2` | `1` | 1'den küçük olamaz |
| `limit` | `20` | `10` | **En fazla 50** — aşan değerler kırpılır |

Gönderilmeyen parametre varsayılanını alır; **gönderilen parametre geçerli olmak zorundadır** (`?page=abc` sessizce yok sayılmaz, 400 döner).

`sort` değeri doğrudan sütun adı olarak kullanılmaz. Kullanılsaydı `?sort=passwordHash` gibi bir istekle izin verilmeyen sütuna göre sıralama yaptırılabilirdi.

Yanıt:

```json
{
  "items": [ { "id": 1, "name": "...", "price": "1499.9", "stock": 10,
               "category": { "id": 1, "name": "Elektronik", "slug": "elektronik" } } ],
  "total": 16, "page": 1, "limit": 10, "totalPages": 2
}
```

`total` listeden çıkarılamayacağı için **aynı süzgeçle ikinci bir sayım sorgusu** çalıştırılır; iki sorgu eş zamanlı yürütülür.

> **`price` bir metindir, sayı değil.** Sütun `DECIMAL(10,2)` tipinde. Normal sayı tipinde ondalık toplamlar tam sonuç vermediği için (`0.1 + 0.2 ≠ 0.3`) metin olarak taşınır. Mobil tarafta ekrana yazarken iki basamağa biçimlendirilecek.

### Yazma uçları

```json
{ "name": "Oyuncu Faresi", "description": "...", "price": "749.90",
  "stock": 25, "categoryId": 1, "imageUrl": "/uploads/urun-....png" }
```

| Alan | Kural |
|---|---|
| `name` | Zorunlu, en fazla 200 karakter |
| `description` | Zorunlu, en fazla 2000 karakter |
| `price` | Zorunlu, negatif olamaz, **en fazla 2 ondalık** |
| `stock` | Tam sayı, 0 olabilir (varsayılan 0) |
| `categoryId` | Zorunlu, **var olmalı** (yoksa 400) |
| `imageUrl` | İsteğe bağlı |

**DELETE neden gerçek silme değil:** satışı yapılmış bir ürünün silinmesi veritabanı düzeyinde engellidir — silinebilseydi geçmiş siparişler hangi ürüne ait olduklarını gösteremezdi. Bu yüzden kayıt yerinde kalır, `isActive` alanı `false` yapılır. Müşteri tarafında **404** görünür.

---

## 5. Görsel yükleme — `/api/upload`

| Yöntem | Adres | Erişim |
|---|---|---|
| POST | `/api/upload` | Yönetici |

**JSON değil**, `multipart/form-data` gönderilir. Alan adı **`image`** olmalıdır.

```bash
curl.exe -s -X POST "http://localhost:3000/api/upload" -H "Authorization: Bearer $admin" -F "image=@yol/dosya.png"
```

Yanıt `201`:

```json
{ "url": "/uploads/urun-1787300520810-444560155642.png", "size": 20635, "mimetype": "image/png" }
```

| Kural | Değer |
|---|---|
| İzinli tipler | `image/png`, `image/jpeg`, `image/webp` |
| En fazla boyut | 2 MB |
| Dosya sayısı | 1 |

**Kullanıcının verdiği dosya adı hiçbir zaman kullanılmaz.** Ad zaman damgası ve rastgele değerden üretilir, uzantı izinli tipler listesinden alınır. Kullanılsaydı üç risk doğardı: üst klasör ifadesi içeren bir adla sunucunun kendi dosyalarının üzerine yazılabilir, aynı adlı iki yükleme birbirini silebilir, çalıştırılabilir uzantılı bir dosya bırakılabilirdi.

Yüklenen dosyalar `/uploads/<ad>` adresinden okunur. Bu klasör **kod çalıştırmaz**, yalnızca dosya sunar.

> Tip denetimi istemcinin bildirdiği etikete dayanır, dolayısıyla kasıtlı bir saldırıyı tek başına engellemez. Asıl koruma uzantının sunucuda belirlenmesi ve klasörün kod çalıştırmamasıdır.

---

## 6. Sepet — `/api/cart` — **hepsi girişli**

| Yöntem | Adres | Ne yapar |
|---|---|---|
| GET | `/` | Sepeti getir |
| POST | `/` | Ekle (varsa adedi artır) |
| PUT | `/:productId` | Adedi belirli bir değere ayarla |
| DELETE | `/:productId` | Ürünü sepetten çıkar |
| DELETE | `/` | Sepeti boşalt |

Beş ucun tamamı tek satırla korunur: `router.use(auth)`. Böylece ileride eklenecek bir uçta bu denetimin unutulması mümkün değildir.

**Kullanıcı kimliği istekten okunmaz**, yalnızca doğrulanmış belirteçten alınır. Aksi hâlde istemci başkasının kimliğini göndererek onun sepetini görebilirdi (IDOR).

**POST** gövdesi: `{ "productId": 1, "quantity": 2 }` — `quantity` gönderilmezse 1.

Aynı ürün ikinci kez eklenirse **yeni satır açılmaz, adet artar** (`upsert`). Bu davranış veritabanı düzeyinde de güvence altındadır: `(userId, productId)` çifti üzerine bileşik benzersizlik kısıtı tanımlıdır. Uygulama katmanındaki denetim tek başına yetmez — iki istek aynı anda gelirse ikisi de kaydı bulunmamış sayıp iki satır oluşturabilirdi.

Bir üründen en fazla **20 adet**. Stok yetmezse **409**.

Yanıt:

```json
{
  "items": [ { "id": 5, "productId": 1, "quantity": 3,
               "product": { "id": 1, "name": "...", "price": "1499.9", "stock": 10, "isActive": true },
               "subtotal": "4499.70", "satinAlinabilir": true } ],
  "totalAmount": "4499.70", "itemCount": 1, "totalQuantity": 3
}
```

> **Sepette fiyat saklanmaz.** Yalnızca `userId`, `productId`, `quantity` tutulur; fiyat ve stok her istekte ürün tablosundan taze okunur. Siparişte ise fiyat kopyalanır. Çelişki değil: **sepet geleceğe, sipariş geçmişe aittir.**

Pasife alınmış veya stoğu yetmeyen satırlar listede kalır ama `satinAlinabilir: false` işaretlenir ve **genel toplama katılmaz**.

---

## 7. Favori — `/api/favorites` — **hepsi girişli**

| Yöntem | Adres | Ne yapar |
|---|---|---|
| GET | `/` | Favori listesi |
| POST | `/:productId` | Favorilerde yoksa ekler, varsa çıkarır |

Tek uç, aç-kapa mantığı. Ayrı ekleme ve çıkarma uçları yazılsaydı istemcinin ürünün mevcut durumunu önceden bilmesi gerekirdi.

```json
{ "productId": 5, "favorited": true }
```

---

## 8. Sipariş — `/api/orders` — **hepsi girişli**

| Yöntem | Adres | Erişim | Ne yapar |
|---|---|---|---|
| POST | `/` | Girişli | Sepetten sipariş oluştur |
| GET | `/` | Girişli | Kendi siparişlerim |
| GET | `/:id` | Girişli | Kendi sipariş detayım |
| GET | `/admin/all` | Yönetici | Tüm siparişler (sayfalı) |
| PATCH | `/:id/status` | Yönetici | Durum güncelle |

### POST /api/orders

```json
{ "addressText": "Guzeltepe Mahallesi, Osmanpasa Caddesi No 7, Eyupsultan/Istanbul" }
```

Adres 10–500 karakter. Sepet boşsa **400**.

**Tek bir transaction içinde dört iş yapılır:**

1. Sepetteki her ürünün stoğu **koşullu** olarak düşürülür
2. `Order` kaydı açılır
3. `OrderItem` kalemleri yazılır — `unitPrice` **satış anındaki fiyattır**
4. Sepet boşaltılır

Herhangi bir adımda hata çıkarsa **hiçbiri uygulanmaz**. Örneğin ikinci üründe stok yetmezse, birinci üründen düşülen stok geri gelir; sepet korunur, yarım sipariş oluşmaz.

Stok düşümü ayrı bir okuma ve yazma adımıyla değil **koşullu tek bir güncelleme** ile yapılır: stok istenen adetten büyük veya eşitse düşülür, değilse hiçbir satır etkilenmez ve işlem hata verir. Önce okuyup sonra yazsaydık, iki isteğin arasına giren üçüncü bir istek stoğu eksiye düşürebilirdi (race condition).

Stok yetmezse veya ürün pasifse **409**.

### GET /api/orders/:id

Sorgu **oturum sahibinin kimliğiyle sınırlıdır**. Yönetici hesabıyla başkasının siparişi istendiğinde **403 değil 404** döner — 403, o kimlikte bir siparişin var olduğunu dolaylı olarak bildirmiş olurdu.

### GET /api/orders/admin/all

`?status=PAID&page=1&limit=10` — `status` beyaz listeden geçer.

### PATCH /api/orders/:id/status

```json
{ "status": "PAID" }
```

**Geçiş tablosu:**

| Mevcut durum | Geçilebilecek durumlar |
|---|---|
| `PENDING` | `PAID`, `CANCELLED` |
| `PAID` | `PREPARING`, `CANCELLED` |
| `PREPARING` | `SHIPPED`, `CANCELLED` |
| `SHIPPED` | `DELIVERED` |
| `DELIVERED` | — (değiştirilemez) |
| `CANCELLED` | — (değiştirilemez) |

Kargoya verilmemiş bir sipariş teslim edilmiş sayılamaz. Geçersiz geçiş **409**, tanımsız durum adı **400** döner.

---

## 9. Statik dosyalar

| Adres | Ne |
|---|---|
| `/uploads/<dosya>` | Yüklenen görseller |

---

## Bulunmayan adres

Tanımsız her adres **404**:

```json
{ "message": "Böyle bir uç bulunamadı." }
```
