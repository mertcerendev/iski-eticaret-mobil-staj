# Sunum Senaryosu

Projeyi birim yetkilisine gösterirken izlenecek sıra, her adımda söylenecekler
ve gelmesi muhtemel sorular.

**Süre:** yaklaşık 15 dakika demo + soru-cevap.

---

## 0. Sunumdan önce (5 dakika)

Üçünün de ayakta olduğu doğrulanmalı:

```bash
docker ps                                # iski_eticaret_db "Up" olmalı
curl http://localhost:3000/api/health    # {"status":"ok",...}
flutter devices                          # emulator-5554 görünmeli
```

Hazırlık:

- Sepet **boş** bırakılmalı (dolu sepetle "sepete ekleme" gösterilemez)
- En az bir favori olsun (favoriler sekmesi boş görünmesin)
- En az üç geçmiş sipariş olsun
- Uygulama giriş ekranında açık olsun (çıkış yapılarak)

Deneme hesabı: `admin@eticaret.com` / `Admin123!`

---

## 1. Giriş ve oturum (2 dk)

| Adım | Gösterilecek | Söylenecek |
|---|---|---|
| Giriş ekranı | Marka adı, iki alan | "Doğrulama hem burada hem sunucuda var. Buradaki hız için — kullanıcı hatayı sunucuya gitmeden görüyor. Asıl denetim sunucuda, çünkü istemci atlatılabilir." |
| Boş alanla dene | Kırmızı uyarı | Sunucuya istek **gitmiyor** |
| Giriş yap | Ana ekran açılır | "Giriş ekranı yönlendirme yapmıyor; oturum durumunu değiştiriyor, hangi ekranın açılacağına `main.dart` tek yerden karar veriyor." |

⭐ **Vurgu:** Uygulamayı kapatıp açtığında tekrar giriş istemiyor. Belirteç
telefonun güvenli deposunda (Android Keystore) duruyor, açılışta sunucuya
soruluyor.

---

## 2. Katalog (3 dk)

| Adım | Gösterilecek |
|---|---|
| Arama kutusuna yaz | Yazarken istek gitmiyor, **yarım saniye** durunca tek istek gidiyor |
| Kategori çipi | Liste süzülüyor, sayfa 1'e dönüyor |
| Sıralama menüsü | Fiyat artan/azalan |
| Aşağı kaydır | Sonsuz kaydırma; sona gelince "Tüm ürünler gösterildi" |
| Stok rozetleri | "Tükendi" kırmızı, "Son 3 adet" turuncu |

⭐ **Vurgu — debounce:** "kulaklık" yazarken 8 harf var ama sunucuya **1 istek**
gidiyor. Her tuşta sayaç sıfırlanıyor.

⭐ **Vurgu — yarış durumu:** Hızlı yazınca istekler sırasız dönebiliyor. Her
istek kendi sıra numarasını taşıyor; geç dönen eski yanıt yok sayılıyor. Yoksa
ekranda önceki aramanın sonucu kalırdı.

---

## 3. Ürün detayı, favori, sepet (3 dk)

| Adım | Gösterilecek |
|---|---|
| Ürüne dokun | Görselin büyüyerek geçmesi (Hero animasyonu) |
| Kalbe bas | **Anında** doluyor — sunucu beklenmiyor |
| Adet seç, sepete ekle | Alt çubuktaki rozet güncelleniyor |
| Sepet sekmesi | Satırlar, adet düğmeleri, sabit toplam şeridi |
| Satırı sola kaydır | Onay penceresi çıkıyor |

⭐ **Vurgu — iyimser güncelleme:** Favoride kalp sunucu beklenmeden doluyor,
hata olursa geri alınıyor. **Sepette bu yok** — çünkü adet değişince tutar da
değişiyor ve para hesabı tahmin edilemez. Sepet sunucunun döndürdüğü tutarı
bekliyor.

---

## 4. Sipariş ve ödeme (3 dk)

| Adım | Gösterilecek |
|---|---|
| "Siparişi Tamamla" | Adres + kart formu |
| Kart numarası yaz | Araya **kendiliğinden boşluk** giriyor |
| Ortadaki haneyi düzelt | İmleç yerinde kalıyor, numara bozulmuyor |
| Geçersiz kart dene | "Kart numarası geçersiz" (Luhn) |
| Geçerli kartla öde | Sipariş onay ekranı |

⭐ **Vurgu — kart saklanmıyor:** Veritabanında yalnızca **son dört hane** ve
karttaki ad var. Tam numara, son kullanma ve güvenlik kodu hiçbir yere
yazılmıyor. Bunu göstermek için:

```bash
# Sunucu günlüğünde tam numara aranıyor — 0 sonuç
grep -c "4242424242424242" backend.log
```

⭐ **Vurgu — Luhn:** Kartın son hanesi rastgele değil, önceki hanelerden
üretilen bir kontrol hanesi. Bu denetim **sahteciliği değil yazım hatasını**
yakalar.

---

## 5. Sipariş geçmişi (2 dk)

Profil → Siparişlerim → bir siparişe dokun.

⭐ **Vurgu — fiyat dondurma:** Bir siparişteki birim fiyat, ürünün bugünkü
fiyatından farklı. Sipariş anındaki fiyat kayda dondurulmuş. Ürün zamlansa bile
geçmiş sipariş değişmiyor — muhasebe için zorunlu.

> Sepet **gelecek**, sipariş **geçmiş**. O yüzden sepette fiyat saklanmıyor,
> siparişte saklanıyor.

---

## 6. Yönetici bölümü (2 dk)

| Adım | Gösterilecek |
|---|---|
| Ana ekran | "Yeni Ürün" düğmesi — yalnızca yöneticide |
| Ürün ekle | Form, kategori listesi, görsel seçimi |
| Kaydet | Liste kendiliğinden tazeleniyor |
| Ürün detayı → çöp kutusu | "Geçmiş siparişlerdeki kaydı korunur" |
| Profil → Sipariş Yönetimi | Bütün siparişler, müşteri bilgisiyle |
| Durum düğmesi | Rozet ve sonraki adım düğmeleri değişiyor |

⭐ **Vurgu — düğmeleri gizlemek yetki denetimi değildir.** Yönetici düğmeleri
yalnızca görünüm kolaylığı. Asıl denetim sunucudaki `requireAdmin` katmanında.
Kanıt:

```bash
curl -X POST http://localhost:3000/api/products -d '{"name":"x"}'
# → 401
```

⭐ **Vurgu — durum makinesi:** Teslim edilmiş sipariş "hazırlanıyor"a geri
dönemiyor. Geçiş tablosu sunucuda; mobil taraf aynı tablonun kopyasını tutup
yalnızca geçerli seçenekleri gösteriyor.

---

## Muhtemel sorular

**"Neden Flutter?"**
Tek koddan Android ve iOS. Stajın ilk günü platform kararı verilirken mobilin
seçilmesinin sebebi buydu.

**"Neden Prisma, düz SQL değil?"**
Şema tek dosyada tanımlı, göç dosyaları ondan üretiliyor, sorgular tip güvenli.
Karmaşık sorgu gerekseydi ham SQL de yazılabilirdi.

**"Para neden `Decimal`?"**
Ondalıklı sayı tipi ikilik sistemde tam yazılamıyor: `0.1 + 0.2` sonucu
`0.30000000000000004` çıkıyor. Küçük görünüyor ama binlerce işlemde birikiyor.
`Decimal` kuruş hassasiyetini koruyor.

**"İki kişi aynı anda son ürünü alırsa?"**
Alamıyor. Stok kontrolü ve düşme tek SQL cümlesinde:
`updateMany(where: { stock: { gte: adet } }, data: { decrement })`. İkinci istek
`count: 0` alıyor ve hata fırlıyor. Ayrıca hepsi bir `transaction` içinde —
ortada hata olursa hiçbiri kalmıyor.

**"Ürünü silince geçmiş siparişler ne oluyor?"**
Ürün gerçekten silinmiyor, `isActive = false` oluyor. Sipariş kalemleri ürüne
bağlı; gerçek silme zaten veritabanı kısıtına takılırdı.

**"Neden 404, 403 değil?"**
Başkasının siparişi istendiğinde "yasak" denseydi o siparişin **var olduğu**
sızdırılırdı. "Yok" demek daha güvenli.

**"Test var mı?"**
Ağa çıkmayan parçalar için 41 birim/bileşen testi var: model dönüşümleri,
doğrulayıcılar, kart biçimlendiricileri, durum geçiş tablosu, ürün kartı.
Sunucu uçları senaryo senaryo `curl` ile denendi.

**"Neyi bitiremediniz?"**
Üç şey bilerek kapsam dışı bırakıldı: e-posta değiştirme (benzersizlik denetimi
ve doğrulama postası gerektiriyor), iptal edilen siparişte stok iadesi (iade
akışı gerektiriyor) ve gerçek ödeme entegrasyonu. Üçü de `README` içinde
"Bilinen konular" başlığında yazılı.

---

## Sunumda kaçınılacaklar

- Ekranları hızlı geçmek — her ekranda bir cümle söylenmeli
- Kod göstermeye çalışmak — soru gelirse gösterilir, kendiliğinden açılmaz
- "Şunu da yapacaktım ama..." demek — kapsam dışı kararlar gerekçesiyle
  anlatılır, eksik gibi sunulmaz
