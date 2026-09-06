# Görseller — Kaynak ve Lisans

## Marka görselleri

Logo, uygulama simgesi ve karşılama afişi **projeye özel** üretilmiştir;
dışarıdan alınmamıştır. Uygulamada şu şekilde kullanılıyorlar:

| Dosya | Nerede | Hazırlık |
|---|---|---|
| `mobile/assets/marka/logo.png` | Açılış ve giriş ekranı | Sunum sayfasından ana kilit kırpıldı, saydam zeminli |
| `mobile/assets/marka/afis.jpg` | Ana sayfa karşılama afişi | 2.4:1 kırpıldı, 1200 piksel genişliğe indirildi |
| `android/.../mipmap-*/ic_launcher*.png` | Telefonun başlatıcı ekranı | Beş yoğunluk için ölçeklendi; uyarlanır simge için mor "N" ayrı katmana ayrıldı |

Marka renkleri: lacivert `#0F1657`, mor `#7259F9`. Uygulama teması bu iki
renkten türetiliyor (`mobile/lib/core/theme/app_theme.dart`).

---

## Ürün görselleri

Katalogdaki 16 ürün görseli **Wikimedia Commons**'tan alınmıştır. Commons
seçilmesinin sebebi, her dosyanın lisansının açıkça belirtilmiş ve makine
tarafından okunabilir olmasıdır.

Görseller kare kırpılıp 600×600 piksele ölçeklendi ve JPEG olarak sunucudaki
`/api/upload` ucundan yüklendi. Ürünlerle ilişkilendirme `PUT /api/products/:id`
ile yapıldı.

> Bu bir eğitim/staj projesidir; görseller ticari olarak kullanılmamaktadır.
> CC BY ve CC BY-SA lisansları atıf gerektirdiği için kaynaklar aşağıda
> listelenmiştir.

| # | Ürün | Commons dosyası | Lisans |
|---|---|---|---|
| 1 | Kablosuz Kulaklık | [2023 Słuchawki Sony WI-XB400 (1).jpg](https://commons.wikimedia.org/wiki/File:2023_S%C5%82uchawki_Sony_WI-XB400_(1).jpg) | CC BY-SA 4.0 |
| 2 | Mekanik Klavye | [Mechanical keyboard example.jpg](https://commons.wikimedia.org/wiki/File:Mechanical_keyboard_example.jpg) | CC BY-SA 4.0 |
| 3 | Akıllı Saat | [Samsung Gear S3.jpg](https://commons.wikimedia.org/wiki/File:Samsung_Gear_S3.jpg) | CC BY-SA 4.0 |
| 4 | Kahve Makinesi | [Coffee machine 2022.jpg](https://commons.wikimedia.org/wiki/File:Coffee_machine_2022.jpg) | CC0 |
| 5 | Su Isıtıcısı | [2023 Czajnik elektryczny N'OVEEN.jpg](https://commons.wikimedia.org/wiki/File:2023_Czajnik_elektryczny_N%27OVEEN.jpg) | CC BY-SA 4.0 |
| 6 | Robot Süpürge | [Robot vacuum cleaner concept study 1994.jpg](https://commons.wikimedia.org/wiki/File:Robot_vacuum_cleaner_concept_study_1994.jpg) | CC BY-SA 4.0 |
| 7 | Pamuklu Tişört | [Ambigram Ideal, polysymmetrical logo printed on a green T-shirt.jpg](https://commons.wikimedia.org/wiki/File:Ambigram_Ideal,_polysymmetrical_logo_printed_on_a_green_T-shirt.jpg) | CC BY-SA 4.0 |
| 8 | Kot Pantolon | [Women's Levi's jeans inside out.jpg](https://commons.wikimedia.org/wiki/File:Women%27s_Levi%27s_jeans_inside_out.jpg) | CC BY-SA 4.0 |
| 9 | Spor Ayakkabı | [2023 Adidas Yeezy 350 V2 EF2905 (1).jpg](https://commons.wikimedia.org/wiki/File:2023_Adidas_Yeezy_350_V2_EF2905_(1).jpg) | CC BY-SA 4.0 |
| 10 | Temiz Kod | [The C Programming Language, 2nd Edition.png](https://commons.wikimedia.org/wiki/File:The_C_Programming_Language,_2nd_Edition.png) | CC0 |
| 11 | Yazılım Mimarisi | [New Science books - Flickr - brewbooks.jpg](https://commons.wikimedia.org/wiki/File:New_Science_books_-_Flickr_-_brewbooks.jpg) | CC BY-SA 2.0 |
| 12 | Veri Yapıları ve Algoritmalar | [Programming language textbooks.jpg](https://commons.wikimedia.org/wiki/File:Programming_language_textbooks.jpg) | Public domain |
| 13 | Yoga Matı | [A woman prepares for her yoga routine.jpg](https://commons.wikimedia.org/wiki/File:A_woman_prepares_for_her_yoga_routine.jpg) | CC BY 2.0 |
| 14 | Dambıl Seti | [Young man lifting dumbbell weight for exercise in fitness gym.jpg](https://commons.wikimedia.org/wiki/File:Young_man_lifting_dumbbell_weight_for_exercise_in_fitness_gym.jpg) | CC BY 2.0 |
| 15 | Koşu Bandı | [Treadmill-gym.jpg](https://commons.wikimedia.org/wiki/File:Treadmill-gym.jpg) | CC BY-SA 4.0 |
| 17 | Oyuncu Faresi | [A computer mouse.jpg](https://commons.wikimedia.org/wiki/File:A_computer_mouse.jpg) | CC BY-SA 4.0 |

---

## Lisans kısaltmaları

| Kısaltma | Anlamı |
|---|---|
| CC0 | Kamu malına bırakılmış, koşulsuz kullanılabilir |
| Public domain | Telifi düşmüş ya da hiç olmamış |
| CC BY 2.0 | Atıf zorunlu |
| CC BY-SA 2.0 / 3.0 / 4.0 | Atıf zorunlu, türetilen eser aynı lisansla paylaşılır |

Tam lisans metinleri için yukarıdaki bağlantılardaki Commons sayfalarına
bakılabilir.
