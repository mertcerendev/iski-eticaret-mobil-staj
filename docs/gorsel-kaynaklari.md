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

---

## Katalog genişletmesi (90 ürün)

Her kategoriye 15 ürün eklenirken görseller yine Commons'tan alındı; kare
kırpılıp 600×600'e ölçeklendi ve `/api/upload` ucundan yüklendi. Arama
otomatik yapıldığı için eşleşmeler elle seçilenler kadar isabetli değil;
gözden geçirilip değiştirilmesi gerekenler olabilir.

| # | Ürün | Kategori | Commons dosyası | Lisans |
|---|---|---|---|---|
| 0 | Bluetooth Hoparlör | Elektronik | [JBL Flip 3 bluetooth speaker (DSCF2653).jpg](https://commons.wikimedia.org/wiki/File:JBL_Flip_3_bluetooth_speaker_(DSCF2653).jpg) | CC BY 4.0 |
| 1 | Taşınabilir Şarj Cihazı | Elektronik | [Turbo Akku Vac Easy Home VC 618WP - battery pack-137](https://commons.wikimedia.org/wiki/File:Turbo_Akku_Vac_Easy_Home_VC_618WP_-_battery_pack-1376.jpg) | CC BY-SA 4.0 |
| 2 | Kablosuz Fare | Elektronik | [A wireless computer mouse.jpg](https://commons.wikimedia.org/wiki/File:A_wireless_computer_mouse.jpg) | CC BY-SA 4.0 |
| 3 | Web Kamerası | Elektronik | [Webcam 01.jpg](https://commons.wikimedia.org/wiki/File:Webcam_01.jpg) | CC0 |
| 4 | Harici SSD 1 TB | Elektronik | [Viper PVP30 Portable SSD 2 TB-3002.jpg](https://commons.wikimedia.org/wiki/File:Viper_PVP30_Portable_SSD_2_TB-3002.jpg) | CC BY-SA 4.0 |
| 5 | USB Bellek 128 GB | Elektronik | [2023 Pendrive'y Verbatim Store ‘n’ Click 16 GB (1).j](https://commons.wikimedia.org/wiki/File:2023_Pendrive%27y_Verbatim_Store_%E2%80%98n%E2%80%99_Click_16_GB_(1).jpg) | CC BY-SA 4.0 |
| 6 | Tablet 10 inç | Elektronik | [Tablet computer.jpg](https://commons.wikimedia.org/wiki/File:Tablet_computer.jpg) | CC BY-SA 4.0 |
| 7 | Kulak İçi Kulaklık | Elektronik | [Bose QuietComfort 25 Acoustic Noise Cancelling Headp](https://commons.wikimedia.org/wiki/File:Bose_QuietComfort_25_Acoustic_Noise_Cancelling_Headphones_with_Carry_Case.jpg) | CC BY-SA 3.0 |
| 9 | Dizüstü Bilgisayar | Elektronik | [IBM Thinkpad R51.jpg](https://commons.wikimedia.org/wiki/File:IBM_Thinkpad_R51.jpg) | CC BY-SA 4.0 |
| 10 | Akıllı Telefon | Elektronik | [Samsung galaxy young.jpg](https://commons.wikimedia.org/wiki/File:Samsung_galaxy_young.jpg) | CC BY-SA 3.0 |
| 11 | Dijital Fotoğraf Makinesi | Elektronik | [Sony Cybershot DSC W210.jpg](https://commons.wikimedia.org/wiki/File:Sony_Cybershot_DSC_W210.jpg) | CC BY-SA 3.0 |
| 12 | Kablosuz Yönlendirici | Elektronik | [ADSL modem router internals labeled.jpg](https://commons.wikimedia.org/wiki/File:ADSL_modem_router_internals_labeled.jpg) | Public domain |
| 13 | Mürekkep Püskürtmeli Yazıcı | Elektronik | [Canon imageRUNNER ADVANCE DX C5860 Color Laser Multi](https://commons.wikimedia.org/wiki/File:Canon_imageRUNNER_ADVANCE_DX_C5860_Color_Laser_Multifunction_Printer_%26_Canon_imageRUNNER_ADVANCE_DX_C7770_Color_Laser_Multifunction_Printer.jpg) | CC BY-SA 4.0 |
| 14 | Kamera Drone | Elektronik | [2015 Dron DJI Phantom 3 Advanced.JPG](https://commons.wikimedia.org/wiki/File:2015_Dron_DJI_Phantom_3_Advanced.JPG) | CC BY-SA 4.0 |
| 15 | Mikrodalga Fırın | Ev Aletleri | [Microwave Oven.jpg](https://commons.wikimedia.org/wiki/File:Microwave_Oven.jpg) | CC BY-SA 4.0 |
| 16 | Blender | Ev Aletleri | [Piña Coladas made in home kitchen blender - 1.jpg](https://commons.wikimedia.org/wiki/File:Pi%C3%B1a_Coladas_made_in_home_kitchen_blender_-_1.jpg) | CC BY-SA 4.0 |
| 17 | Ekmek Kızartma Makinesi | Ev Aletleri | [Hamilton Beach Toaster Oven Model 31300 - In corner.](https://commons.wikimedia.org/wiki/File:Hamilton_Beach_Toaster_Oven_Model_31300_-_In_corner.jpg) | CC BY-SA 4.0 |
| 18 | Buharlı Ütü | Ev Aletleri | [Electric steam iron.jpg](https://commons.wikimedia.org/wiki/File:Electric_steam_iron.jpg) | CC BY-SA 3.0 |
| 19 | Saç Kurutma Makinesi | Ev Aletleri | [HITACHI HAIR DRYER HD-1650.jpg](https://commons.wikimedia.org/wiki/File:HITACHI_HAIR_DRYER_HD-1650.jpg) | CC BY-SA 4.0 |
| 20 | Buzdolabı | Ev Aletleri | [Open refrigerator with food at night.jpg](https://commons.wikimedia.org/wiki/File:Open_refrigerator_with_food_at_night.jpg) | CC BY-SA 4.0 |
| 21 | Çamaşır Makinesi | Ev Aletleri | [Front Load Washing Machine.jpg](https://commons.wikimedia.org/wiki/File:Front_Load_Washing_Machine.jpg) | CC BY-SA 3.0 |
| 22 | Bulaşık Makinesi | Ev Aletleri | [KitchenAid home dishwasher - Open.jpg](https://commons.wikimedia.org/wiki/File:KitchenAid_home_dishwasher_-_Open.jpg) | CC BY-SA 4.0 |
| 23 | Elektrikli Süpürge | Ev Aletleri | [Vintage Universal Rocket Shaped Canister Vacuum Clea](https://commons.wikimedia.org/wiki/File:Vintage_Universal_Rocket_Shaped_Canister_Vacuum_Cleaner,_Model_VC6702,_Made_In_USA,_A_Good_Prop_For_A_Flash_Gordon_Spaceship,_Circa_1947_(22370347335).jpg) | CC BY-SA 2.0 |
| 24 | Yağsız Fritöz | Ev Aletleri | [Untraditional air fryer beignets in toaster oven.jpg](https://commons.wikimedia.org/wiki/File:Untraditional_air_fryer_beignets_in_toaster_oven.jpg) | CC BY-SA 4.0 |
| 25 | Mutfak Robotu | Ev Aletleri | [Food Processor 2.jpg](https://commons.wikimedia.org/wiki/File:Food_Processor_2.jpg) | CC BY-SA 3.0 |
| 26 | Ayaklı Vantilatör | Ev Aletleri | [Ventilator BW 2026-06-19 16-42-30 running.jpg](https://commons.wikimedia.org/wiki/File:Ventilator_BW_2026-06-19_16-42-30_running.jpg) | CC BY-SA 4.0 |
| 27 | Su Sebili | Ev Aletleri | [Water-dispenser-aqua-clara.jpg](https://commons.wikimedia.org/wiki/File:Water-dispenser-aqua-clara.jpg) | CC BY-SA 4.0 |
| 28 | Elektrikli Isıtıcı | Ev Aletleri | [Space heater.jpg](https://commons.wikimedia.org/wiki/File:Space_heater.jpg) | CC0 |
| 29 | Stand Mikser | Ev Aletleri | [Миксер ДОМОТЕК.jpg](https://commons.wikimedia.org/wiki/File:%D0%9C%D0%B8%D0%BA%D1%81%D0%B5%D1%80_%D0%94%D0%9E%D0%9C%D0%9E%D0%A2%D0%95%D0%9A.jpg) | CC BY-SA 4.0 |
| 30 | Kapüşonlu Sweatshirt | Giyim | [Fastcolors-men fashion sweatshirt-back-printed.jpg](https://commons.wikimedia.org/wiki/File:Fastcolors-men_fashion_sweatshirt-back-printed.jpg) | CC BY-SA 2.5 |
| 31 | Deri Ceket | Giyim | [Black worn leather jacket detail 1.jpg](https://commons.wikimedia.org/wiki/File:Black_worn_leather_jacket_detail_1.jpg) | CC0 |
| 32 | Klasik Gömlek | Giyim | [Camisade puño doble.jpg](https://commons.wikimedia.org/wiki/File:Camisade_pu%C3%B1o_doble.jpg) | CC BY-SA 3.0 |
| 33 | Yün Kazak | Giyim | [Swiss Army Wool Sweater (15695462777).jpg](https://commons.wikimedia.org/wiki/File:Swiss_Army_Wool_Sweater_(15695462777).jpg) | CC BY 2.0 |
| 34 | Şort | Giyim | [Cargo shorts.jpg](https://commons.wikimedia.org/wiki/File:Cargo_shorts.jpg) | CC0 |
| 35 | Yazlık Elbise | Giyim | [Woman modelling a summer dress, 1954 (19270529340).j](https://commons.wikimedia.org/wiki/File:Woman_modelling_a_summer_dress,_1954_(19270529340).jpg) | No restrictions |
| 36 | Midi Etek | Giyim | [Woman wearing black turtleneck and blue skirt.jpg](https://commons.wikimedia.org/wiki/File:Woman_wearing_black_turtleneck_and_blue_skirt.jpg) | CC BY 2.0 |
| 37 | Kışlık Mont | Giyim | [HK TKO 將軍澳 Tseung Kwan O PopCorn mall shop Uniqlo Cl](https://commons.wikimedia.org/wiki/File:HK_TKO_%E5%B0%87%E8%BB%8D%E6%BE%B3_Tseung_Kwan_O_PopCorn_mall_shop_Uniqlo_Clothing_Store_%E5%86%AC%E5%AD%A3_winter_top_December_2022_Px3_24_Parka_jackets.jpg) | CC BY-SA 4.0 |
| 38 | Örgü Bere | Giyim | [Beanie hat by Polo Ralph Lauren.jpg](https://commons.wikimedia.org/wiki/File:Beanie_hat_by_Polo_Ralph_Lauren.jpg) | CC BY 2.0 |
| 39 | Yün Atkı | Giyim | [Knit cap and loop scarf set.jpg](https://commons.wikimedia.org/wiki/File:Knit_cap_and_loop_scarf_set.jpg) | CC BY-SA 4.0 |
| 40 | Kışlık Eldiven | Giyim | [Two pairs of mens leather gloves from Randers Handsk](https://commons.wikimedia.org/wiki/File:Two_pairs_of_mens_leather_gloves_from_Randers_Handsker.jpg) | CC BY-SA 4.0 |
| 41 | Çorap Seti | Giyim | [BLW Pair of socks.jpg](https://commons.wikimedia.org/wiki/File:BLW_Pair_of_socks.jpg) | CC BY-SA 2.0 uk |
| 42 | Deri Kemer | Giyim | [Germany Belt-and-Buckle-02.jpg](https://commons.wikimedia.org/wiki/File:Germany_Belt-and-Buckle-02.jpg) | CC BY-SA 3.0 |
| 43 | Deri Bot | Giyim | [Leather boots men's.jpg](https://commons.wikimedia.org/wiki/File:Leather_boots_men%27s.jpg) | CC BY-SA 4.0 |
| 44 | Şapka | Giyim | [Baseball cap.png](https://commons.wikimedia.org/wiki/File:Baseball_cap.png) | CC BY 4.0 |
| 45 | Suç ve Ceza | Kitap | [Melania Memoir book cover.jpg](https://commons.wikimedia.org/wiki/File:Melania_Memoir_book_cover.jpg) | Public domain |
| 46 | Sefiller | Kitap | [Old Books 01.JPG](https://commons.wikimedia.org/wiki/File:Old_Books_01.JPG) | CC0 |
| 47 | Savaş ve Barış | Kitap | [PediaPress Hardcover pile02.jpg](https://commons.wikimedia.org/wiki/File:PediaPress_Hardcover_pile02.jpg) | CC BY-SA 3.0 |
| 48 | Dönüşüm | Kitap | [Book of Hours (Use of Metz) Fol. 27r, Decorated Init](https://commons.wikimedia.org/wiki/File:Book_of_Hours_(Use_of_Metz)_Fol._27r,_Decorated_Initials.tif) | Public domain |
| 49 | Şiir Seçkisi | Kitap | [JTF Guantanamo Sailor Publishes Poetry Book DVIDS216](https://commons.wikimedia.org/wiki/File:JTF_Guantanamo_Sailor_Publishes_Poetry_Book_DVIDS216251.jpg) | Public domain |
| 50 | Genel Kültür Ansiklopedisi | Kitap | [Great Ukrainian Encyclopedia Volume 1 title page.png](https://commons.wikimedia.org/wiki/File:Great_Ukrainian_Encyclopedia_Volume_1_title_page.png) | Public domain |
| 51 | Türkçe Sözlük | Kitap | [Dictionary of plants book cover.png](https://commons.wikimedia.org/wiki/File:Dictionary_of_plants_book_cover.png) | Public domain |
| 52 | Dünya Atlası | Kitap | [Atlas of Heinrich Thomé - No 14. Memel.jpg](https://commons.wikimedia.org/wiki/File:Atlas_of_Heinrich_Thom%C3%A9_-_No_14._Memel.jpg) | Public domain |
| 53 | Yemek Kitabı | Kitap | [Mrs. Welch's Cookbook, published in 1884.jpg](https://commons.wikimedia.org/wiki/File:Mrs._Welch%27s_Cookbook,_published_in_1884.jpg) | Public domain |
| 54 | Çizgi Roman Seti | Kitap | [Fan Expo 2014 - Stacks (9669608946).jpg](https://commons.wikimedia.org/wiki/File:Fan_Expo_2014_-_Stacks_(9669608946).jpg) | CC BY 2.0 |
| 55 | Fizik Ders Kitabı | Kitap | [FL Textbook Ban 2023.jpg](https://commons.wikimedia.org/wiki/File:FL_Textbook_Ban_2023.jpg) | CC BY-SA 4.0 |
| 56 | Çocuk Masalları | Kitap | [Children Books Tunisia.jpg](https://commons.wikimedia.org/wiki/File:Children_Books_Tunisia.jpg) | CC BY-SA 2.0 |
| 57 | Tarih Kitabı | Kitap | [Hanna book cover.jpg](https://commons.wikimedia.org/wiki/File:Hanna_book_cover.jpg) | Public domain |
| 58 | Defter ve Ajanda | Kitap | [Notebook (NIH BioArt 394).png](https://commons.wikimedia.org/wiki/File:Notebook_(NIH_BioArt_394).png) | Public domain |
| 59 | Fotoğraf Albümü Kitabı | Kitap | [Coffee Table book stack.jpg](https://commons.wikimedia.org/wiki/File:Coffee_Table_book_stack.jpg) | CC BY-SA 4.0 |
| 60 | Futbol Topu | Spor | [Giant Soccer Ball.jpg](https://commons.wikimedia.org/wiki/File:Giant_Soccer_Ball.jpg) | CC BY-SA 4.0 |
| 61 | Basketbol Topu | Spor | [Bouncing ball strobe edit.jpg](https://commons.wikimedia.org/wiki/File:Bouncing_ball_strobe_edit.jpg) | CC BY-SA 3.0 |
| 62 | Tenis Raketi | Spor | [Richèl Hogenkamp - Masters de Madrid 2015 - 11.jpg](https://commons.wikimedia.org/wiki/File:Rich%C3%A8l_Hogenkamp_-_Masters_de_Madrid_2015_-_11.jpg) | CC BY-SA 4.0 |
| 63 | Şehir Bisikleti | Spor | [Bike on a snowy street in Quebec City at night.jpg](https://commons.wikimedia.org/wiki/File:Bike_on_a_snowy_street_in_Quebec_City_at_night.jpg) | CC0 |
| 64 | Kaykay | Spor | [Zawody w skateboardingu Street of Mediateka, Zagłębi](https://commons.wikimedia.org/wiki/File:Zawody_w_skateboardingu_Street_of_Mediateka,_Zag%C5%82%C4%99biowska_Mediateka,_ulica_Ko%C5%9Bcielna,_Sosnowiec,_22_czerwca_2024_01.jpg) | CC BY 4.0 |
| 65 | Paten | Spor | [Impala Marawa Quad Skates Comparison.jpg](https://commons.wikimedia.org/wiki/File:Impala_Marawa_Quad_Skates_Comparison.jpg) | CC BY-SA 4.0 |
| 66 | Boks Eldiveni | Spor | [Boxing gloves.jpg](https://commons.wikimedia.org/wiki/File:Boxing_gloves.jpg) | CC BY 2.5 |
| 67 | Yüzücü Gözlüğü | Spor | [Girl with swimming board.jpg](https://commons.wikimedia.org/wiki/File:Girl_with_swimming_board.jpg) | CC BY 2.0 |
| 68 | Kayak Takımı | Spor | [Rossignol Experience 88 Ti Skis.jpg](https://commons.wikimedia.org/wiki/File:Rossignol_Experience_88_Ti_Skis.jpg) | CC BY-SA 4.0 |
| 69 | Voleybol Topu | Spor | [Beach volleyball ball.png](https://commons.wikimedia.org/wiki/File:Beach_volleyball_ball.png) | Public domain |
| 70 | Atlama İpi | Spor | [Ghanaian kid (skipping rope) 02.jpg](https://commons.wikimedia.org/wiki/File:Ghanaian_kid_(skipping_rope)_02.jpg) | CC BY-SA 4.0 |
| 71 | Direnç Bandı Seti | Spor | [Strength band.png](https://commons.wikimedia.org/wiki/File:Strength_band.png) | CC BY-SA 4.0 |
| 72 | Kondisyon Bisikleti | Spor | [Stationary bikes at a gym.jpg](https://commons.wikimedia.org/wiki/File:Stationary_bikes_at_a_gym.jpg) | CC BY-SA 4.0 |
| 73 | Halter Seti | Spor | [Gewichtschijf.jpg](https://commons.wikimedia.org/wiki/File:Gewichtschijf.jpg) | Public domain |
| 74 | Trekking Sırt Çantası | Spor | [Plecak Hiker 50 L HiMountain.jpg](https://commons.wikimedia.org/wiki/File:Plecak_Hiker_50_L_HiMountain.jpg) | CC0 |
| 75 | Yapı Blokları Seti | Oyuncak | [Pile of light gray LEGO bricks at a LEGO store.jpg](https://commons.wikimedia.org/wiki/File:Pile_of_light_gray_LEGO_bricks_at_a_LEGO_store.jpg) | CC BY-SA 4.0 |
| 76 | Peluş Ayı | Oyuncak | [2023 Pluszowy miś.jpg](https://commons.wikimedia.org/wiki/File:2023_Pluszowy_mi%C5%9B.jpg) | CC BY-SA 4.0 |
| 77 | Yapboz 1000 Parça | Oyuncak | [Red jigsaw puzzle pieces 2.jpg](https://commons.wikimedia.org/wiki/File:Red_jigsaw_puzzle_pieces_2.jpg) | CC0 |
| 78 | Oyuncak Araba Seti | Oyuncak | [Toy car, 587643.jpg](https://commons.wikimedia.org/wiki/File:Toy_car,_587643.jpg) | CC BY 4.0 |
| 79 | Oyuncak Bebek | Oyuncak | [Doosje met wit plastic poppenhuis meubilair, keukens](https://commons.wikimedia.org/wiki/File:Doosje_met_wit_plastic_poppenhuis_meubilair,_keukenset_%E2%80%9CDolly%E2%80%99s_Furniture%E2%80%9D,_objectnr_74328-A.JPG) | CC BY-SA 3.0 |
| 80 | Ahşap Bloklar | Oyuncak | [A pile of alphabet wooden blocks.jpg](https://commons.wikimedia.org/wiki/File:A_pile_of_alphabet_wooden_blocks.jpg) | CC BY 4.0 |
| 81 | Uzaktan Kumandalı Araba | Oyuncak | [Jongetje speelt met radiografisch bestuurde speelgoe](https://commons.wikimedia.org/wiki/File:Jongetje_speelt_met_radiografisch_bestuurde_speelgoedbus_Boy_playing_with_a_radio-controlled_toy_bus.jpg) | Public domain |
| 82 | Zeka Küpü | Oyuncak | [Rubiks cube by keqs.jpg](https://commons.wikimedia.org/wiki/File:Rubiks_cube_by_keqs.jpg) | CC BY-SA 3.0 |
| 83 | Satranç Takımı | Oyuncak | [Opening chess position from black side.jpg](https://commons.wikimedia.org/wiki/File:Opening_chess_position_from_black_side.jpg) | CC BY-SA 3.0 |
| 84 | Oyun Hamuru Seti | Oyuncak | [Stratacutbaby.jpg](https://commons.wikimedia.org/wiki/File:Stratacutbaby.jpg) | CC BY-SA 3.0 |
| 85 | Oyuncak Tren Seti | Oyuncak | [Model Train Roundhouse.jpg](https://commons.wikimedia.org/wiki/File:Model_Train_Roundhouse.jpg) | CC BY-SA 4.0 |
| 86 | Uçurtma | Oyuncak | [Kite, flying a kite, colorful Fortepan 60629.jpg](https://commons.wikimedia.org/wiki/File:Kite,_flying_a_kite,_colorful_Fortepan_60629.jpg) | CC BY-SA 3.0 |
| 87 | Su Tabancası | Oyuncak | [Water Gun.jpg](https://commons.wikimedia.org/wiki/File:Water_Gun.jpg) | CC BY-SA 4.0 |
| 88 | Kutu Oyunu | Oyuncak | [Castles of Burgundy (Board Game).jpg](https://commons.wikimedia.org/wiki/File:Castles_of_Burgundy_(Board_Game).jpg) | CC0 |
| 89 | Oyuncak Mutfak Seti | Oyuncak | [Toy kitchen set.jpg](https://commons.wikimedia.org/wiki/File:Toy_kitchen_set.jpg) | CC BY-SA 4.0 |
