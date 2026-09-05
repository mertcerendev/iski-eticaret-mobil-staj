import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/core/dogrulayicilar.dart';
import 'package:mobile/core/kart_bicimlendiriciler.dart';
import 'package:mobile/models/kategori.dart';
import 'package:mobile/models/sayfali_sonuc.dart';
import 'package:mobile/models/sepet.dart';
import 'package:mobile/models/siparis.dart';
import 'package:mobile/models/urun.dart';
import 'package:mobile/providers/favori_provider.dart';
import 'package:mobile/widgets/siparis_durum_rozeti.dart';
import 'package:mobile/widgets/urun_karti.dart';

void main() {
  // Uygulamanın kökü açılışta güvenli depoya ve sunucuya başvurduğu için
  // doğrudan çizilemez. Bunun yerine dışa bağımlılığı olmayan parçalar
  // sınanır: kart bileşeni, model dönüşümleri ve doğrulayıcılar.

  group('UrunKarti', () {
    /// Kart ızgara hücresi için tasarlandı; testte de hücreye benzer
    /// sınırlı bir alan verilir, yoksa dikey taşma olur.
    ///
    /// Karttaki kalp düğmesi `FavoriProvider`'ı okuduğu için sağlayıcı da
    /// ağaca eklenir. Sağlayıcı ağ isteği atmaz; yalnızca boş başlar.
    Widget sar(Urun urun) {
      return ChangeNotifierProvider(
        create: (_) => FavoriProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 290,
                child: UrunKarti(urun: urun, heroOneki: 'test'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('ürün adını, kategorisini ve fiyatını gösterir', (tester) async {
      await tester.pumpWidget(
        sar(
          const Urun(
            id: 1,
            ad: 'Kablosuz Kulaklık',
            aciklama: 'Aktif gürültü engelleme.',
            fiyat: 1499.90,
            stok: 25,
            kategoriId: 1,
            kategori: Kategori(id: 1, ad: 'Elektronik', slug: 'elektronik'),
          ),
        ),
      );

      expect(find.text('Kablosuz Kulaklık'), findsOneWidget);
      expect(find.text('Elektronik'), findsOneWidget);
      expect(find.text('1499.90 TL'), findsOneWidget);

      // Stok yeterliyken rozet gösterilmez; ekran gereksiz kalabalıklaşmasın.
      expect(find.text('Stokta'), findsNothing);
    });

    testWidgets('stok bittiğinde "Tükendi" rozeti çıkar', (tester) async {
      await tester.pumpWidget(
        sar(
          const Urun(
            id: 2,
            ad: 'Mekanik Klavye',
            aciklama: 'Mavi switch.',
            fiyat: 899.90,
            stok: 0,
            kategoriId: 1,
          ),
        ),
      );

      expect(find.text('Tükendi'), findsOneWidget);
    });

    testWidgets('stok 5\'in altındayken kalan adedi yazar', (tester) async {
      await tester.pumpWidget(
        sar(
          const Urun(
            id: 3,
            ad: 'Akıllı Saat',
            aciklama: 'Nabız takibi.',
            fiyat: 2299.00,
            stok: 3,
            kategoriId: 1,
          ),
        ),
      );

      expect(find.text('Son 3 adet'), findsOneWidget);
    });
  });

  group('Urun.fromJson', () {
    test('sunucudan gelen JSON nesneye çevrilir', () {
      final urun = Urun.fromJson({
        'id': 3,
        'name': 'Akıllı Saat',
        'description': 'Nabız ve uyku takibi.',
        'price': '2299', // Decimal alan metin olarak gelir
        'stock': 3,
        'imageUrl': null,
        'isActive': true,
        'categoryId': 1,
        'category': {'id': 1, 'name': 'Elektronik', 'slug': 'elektronik'},
      });

      expect(urun.ad, 'Akıllı Saat');
      expect(urun.fiyat, 2299.0);
      expect(urun.kategori?.ad, 'Elektronik');
      expect(urun.sonUrunler, isTrue);
    });
  });

  group('SayfaliSonuc', () {
    test('sayfa zarfı çözülür ve son sayfa hesaplanır', () {
      final sonuc = SayfaliSonuc.fromJson({
        'items': [
          {
            'id': 1,
            'name': 'Kablosuz Kulaklık',
            'description': '',
            'price': '1499.9',
            'stock': 25,
            'isActive': true,
            'categoryId': 1,
          },
        ],
        'total': 17,
        'page': 1,
        'limit': 10,
        'totalPages': 2,
      }, Urun.fromJson);

      expect(sonuc.kayitlar, hasLength(1));
      expect(sonuc.kayitlar.first.fiyat, 1499.9);
      expect(sonuc.toplam, 17);
      // Sayfalama alanları doğru çözülmeli; "daha var mı" kararını
      // `UrunProvider` bu iki alandan veriyor.
      expect(sonuc.sayfa, 1);
      expect(sonuc.toplamSayfa, 2);
    });
  });

  group('Dogrulayicilar', () {
    test('geçersiz e-posta reddedilir', () {
      expect(Dogrulayicilar.eposta(''), isNotNull);
      expect(Dogrulayicilar.eposta('mert'), isNotNull);
      expect(Dogrulayicilar.eposta('mert@test'), isNotNull);
      expect(Dogrulayicilar.eposta('mert@test.com'), isNull);
    });

    test('kısa parola reddedilir', () {
      expect(Dogrulayicilar.parola('1234'), isNotNull);
      expect(Dogrulayicilar.parola('sifre1234'), isNull);
    });

    test('eşleşmeyen parola tekrarı reddedilir', () {
      expect(Dogrulayicilar.parolaTekrari('abc', 'abd'), isNotNull);
      expect(Dogrulayicilar.parolaTekrari('sifre1234', 'sifre1234'), isNull);
    });
  });

  group('Sepet.fromJson', () {
    test('satırlar, toplam ve alınamayan ürün bayrağı çözülür', () {
      final sepet = Sepet.fromJson({
        'items': [
          {
            'id': 9,
            'productId': 1,
            'quantity': 2,
            'product': {
              'id': 1,
              'name': 'Kablosuz Kulaklık',
              'price': '1499.90',
              'stock': 25,
              'isActive': true,
            },
            'subtotal': '2999.80',
            'satinAlinabilir': true,
          },
          {
            'id': 10,
            'productId': 2,
            'quantity': 1,
            'product': {
              'id': 2,
              'name': 'Mekanik Klavye',
              'price': '899.90',
              'stock': 0,
              'isActive': true,
            },
            'subtotal': '899.90',
            'satinAlinabilir': false,
          },
        ],
        // Sunucu stoğu biten satırı toplama katmıyor: 2999.80 + 0
        'totalAmount': '2999.80',
        'itemCount': 2,
        'totalQuantity': 3,
      });

      expect(sepet.satirlar, hasLength(2));
      expect(sepet.satirlar.first.araToplam, 2999.80);
      expect(sepet.satirlar.last.satinAlinabilir, isFalse);
      expect(sepet.toplamTutar, 2999.80);
      expect(sepet.toplamAdet, 3);
      expect(sepet.bosMu, isFalse);
    });

    test('boş sepet başlangıç değeri', () {
      const sepet = Sepet.bos();

      expect(sepet.bosMu, isTrue);
      expect(sepet.toplamAdet, 0);
      expect(sepet.toplamMetni, '0.00 TL');
    });
  });

  group('Siparis.fromJson', () {
    final siparis = Siparis.fromJson({
      'id': 3,
      'userId': 1,
      'status': 'PAID',
      'totalAmount': '31499.70',
      'addressText': 'Guzeltepe Mahallesi, Osmanpasa Caddesi No 7',
      'cardLast4': '4242',
      'cardHolderName': 'MERT CEREN',
      'createdAt': '2026-09-01T09:30:00.000Z',
      'items': [
        {
          'id': 5,
          'productId': 1,
          'quantity': 3,
          'unitPrice': '1999.9',
          'product': {'id': 1, 'name': 'Kablosuz Kulaklik', 'imageUrl': null},
        },
        {
          'id': 6,
          'productId': 9,
          'quantity': 2,
          'unitPrice': '12750',
          'product': {'id': 9, 'name': 'Koşu Bandı', 'imageUrl': null},
        },
      ],
    });

    test('durum, tutar ve kalemler çözülür', () {
      expect(siparis.durum, SiparisDurumu.odendi);
      expect(siparis.durum.etiket, 'Ödendi');
      expect(siparis.toplamTutar, 31499.70);
      expect(siparis.kalemler, hasLength(2));
      expect(siparis.toplamAdet, 5);
    });

    test('birim fiyat sipariş anındaki fiyattır, ara toplam ondan hesaplanır', () {
      final kalem = siparis.kalemler.first;

      expect(kalem.birimFiyat, 1999.9);
      expect(kalem.araToplam, closeTo(5999.7, 0.001));
    });

    test('kartın yalnız son dört hanesi taşınır', () {
      expect(siparis.kartSonDort, '4242');
      expect(siparis.kartMetni, '**** **** **** 4242');
    });

    test('sipariş numarası okunur biçimde üretilir', () {
      expect(siparis.numara, 'SP-000003');
    });

    test('tanınmayan durum uygulamayı çökertmez', () {
      final bilinmeyen = Siparis.fromJson({
        'id': 1,
        'status': 'REFUNDED',
        'totalAmount': '10',
        'addressText': '',
        'createdAt': '2026-09-01T09:30:00.000Z',
        'items': [],
      });

      expect(bilinmeyen.durum, SiparisDurumu.bekliyor);
    });
  });

  group('Urun hesaplanan alanlar', () {
    Urun urunYap(int stok) => Urun(
          id: 1,
          ad: 'Test',
          aciklama: '',
          fiyat: 10,
          stok: stok,
          kategoriId: 1,
        );

    test('stok eşiğine göre metin ve bayraklar', () {
      // Eşik dört ayrı yerde okunuyor (kart rozeti, detay satırı, satır rengi,
      // sepet uyarısı). Tek yerde tanımlı olduğu buradan sabitleniyor.
      expect(urunYap(0).stoktaVar, isFalse);
      expect(urunYap(0).stokMetni, 'Tükendi');

      expect(urunYap(3).sonUrunler, isTrue);
      expect(urunYap(3).stokMetni, 'Son 3 adet');

      expect(urunYap(5).sonUrunler, isFalse);
      expect(urunYap(5).stokMetni, 'Stokta');
    });

    test('fiyat her zaman iki basamakla yazılır', () {
      expect(urunYap(1).fiyatMetni, '10.00 TL');
    });
  });

  group('Urun.sayiyaCevir', () {
    test('sunucudan metin gelen para değeri sayıya çevrilir', () {
      // Prisma `Decimal` alanlarını metin olarak gönderiyor; ondalıklı sayıya
      // çevrim yalnızca gösterim için, hesap sunucuda kalıyor.
      expect(Urun.sayiyaCevir('1499.90'), 1499.90);
      expect(Urun.sayiyaCevir(1499.9), 1499.9);
      expect(Urun.sayiyaCevir(null), 0);
      expect(Urun.sayiyaCevir('bozuk'), 0);
    });

    test('sipariş modeli de aynı çeviriciyi kullanıyor', () {
      // Bu çevirici bir ara `siparis.dart` içinde ikinci kez yazılmıştı;
      // kopya kaldırıldı, tek kaynak `Urun.sayiyaCevir`.
      final siparis = Siparis.fromJson({
        'id': 1,
        'totalAmount': '31499.70',
        'status': 'PAID',
        'addressText': 'Test adresi, Eyupsultan/Istanbul',
        'createdAt': '2026-09-04T08:00:00.000Z',
        'items': [
          {
            'productId': 1,
            'quantity': 3,
            'unitPrice': '1999.90',
            'product': {'name': 'Kulaklik'},
          },
        ],
      });

      expect(siparis.toplamTutar, 31499.70);
      expect(siparis.kalemler.first.birimFiyat, 1999.90);
    });
  });

  group('Sepet.bos', () {
    test('boş sepet null yerine çalışan bir nesne', () {
      // Sepet `null` olsaydı onu okuyan her yer denetim yapmak zorunda
      // kalırdı; biri unutulduğunda uygulama çökerdi.
      const sepet = Sepet.bos();

      expect(sepet.bosMu, isTrue);
      expect(sepet.toplamAdet, 0);
      expect(sepet.satirlar, isEmpty);
      expect(sepet.toplamMetni, '0.00 TL');
    });
  });

  group('SiparisDurumRozeti', () {
    Future<void> ciz(WidgetTester tester, SiparisDurumu durum) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SiparisDurumRozeti(durum: durum)),
        ),
      );
    }

    testWidgets('her durum kendi Türkçe etiketiyle çizilir', (tester) async {
      // Sunucudaki altı durumun hepsi ekranda karşılık bulmalı; biri eksik
      // kalırsa kullanıcı siparişinin nerede olduğunu göremez.
      for (final durum in SiparisDurumu.values) {
        await ciz(tester, durum);

        expect(
          find.text(durum.etiket),
          findsOneWidget,
          reason: '${durum.anahtar} için etiket çizilmedi',
        );
      }
    });

    testWidgets('teslim ve iptal farklı renklerde gösterilir', (tester) async {
      // Renk kararı modelde değil bu widget'ta; iki uç durumun ayrışması
      // rozetin işini yaptığının kanıtı.
      await ciz(tester, SiparisDurumu.teslimEdildi);
      final teslim = tester.widget<Icon>(find.byType(Icon)).color;

      await ciz(tester, SiparisDurumu.iptalEdildi);
      final iptal = tester.widget<Icon>(find.byType(Icon)).color;

      expect(teslim, isNot(equals(iptal)));
    });

    testWidgets('büyük kip yazıyı büyütür', (tester) async {
      await ciz(tester, SiparisDurumu.odendi);
      final kucuk = tester.widget<Text>(find.text('Ödendi')).style!.fontSize!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiparisDurumRozeti(
              durum: SiparisDurumu.odendi,
              buyuk: true,
            ),
          ),
        ),
      );
      final buyuk = tester.widget<Text>(find.text('Ödendi')).style!.fontSize!;

      expect(buyuk, greaterThan(kucuk));
    });
  });

  group('SiparisDurumu geçiş tablosu', () {
    test('sunucudaki DURUM_GECISLERI ile birebir aynı', () {
      // Bu tablo sunucudaki `order.service.js` içindeki tablonun aynası.
      // Ayrışırsa yönetici ekranı sunucunun reddedeceği bir geçiş sunar.
      expect(SiparisDurumu.bekliyor.sonrakiler,
          [SiparisDurumu.odendi, SiparisDurumu.iptalEdildi]);
      expect(SiparisDurumu.odendi.sonrakiler,
          [SiparisDurumu.hazirlaniyor, SiparisDurumu.iptalEdildi]);
      expect(SiparisDurumu.hazirlaniyor.sonrakiler,
          [SiparisDurumu.kargoda, SiparisDurumu.iptalEdildi]);
      expect(SiparisDurumu.kargoda.sonrakiler, [SiparisDurumu.teslimEdildi]);
    });

    test('biten durumlardan çıkış yok', () {
      // Teslim edilmiş sipariş "hazırlanıyor"a geri dönemez.
      expect(SiparisDurumu.teslimEdildi.sonrakiler, isEmpty);
      expect(SiparisDurumu.iptalEdildi.sonrakiler, isEmpty);
    });
  });

  group('SiparisMusterisi', () {
    test('yönetici listelemesindeki kullanıcı bilgisi çözülür', () {
      final siparis = Siparis.fromJson({
        'id': 7,
        'totalAmount': '250.00',
        'status': 'PAID',
        'addressText': 'Test adresi, Eyupsultan/Istanbul',
        'createdAt': '2026-09-04T08:00:00.000Z',
        'items': [],
        'user': {
          'id': 3,
          'fullName': 'Ayse Yilmaz',
          'email': 'ayse@ornek.com',
        },
      });

      expect(siparis.musteri, isNotNull);
      expect(siparis.musteri!.adSoyad, 'Ayse Yilmaz');
      expect(siparis.musteri!.eposta, 'ayse@ornek.com');
    });

    test('durum güncellemesinden sonra müşteri bilgisi korunur', () {
      // PATCH yanıtı `user` alanını döndürmüyor. Dönen kayıt olduğu gibi
      // konulsaydı yönetici ekranındaki müşteri satırı kaybolurdu.
      final eldeki = Siparis.fromJson({
        'id': 9,
        'totalAmount': '300.00',
        'status': 'PAID',
        'addressText': 'Test adresi, Eyupsultan/Istanbul',
        'createdAt': '2026-09-04T08:00:00.000Z',
        'items': [],
        'user': {'id': 3, 'fullName': 'Ayse Yilmaz', 'email': 'a@b.com'},
      });

      final sunucudanGelen = Siparis.fromJson({
        'id': 9,
        'totalAmount': '300.00',
        'status': 'PREPARING',
        'addressText': 'Test adresi, Eyupsultan/Istanbul',
        'createdAt': '2026-09-04T08:00:00.000Z',
        'items': [],
      });

      final birlesik = sunucudanGelen.musteriIle(eldeki.musteri);

      expect(birlesik.durum, SiparisDurumu.hazirlaniyor);
      expect(birlesik.musteri?.adSoyad, 'Ayse Yilmaz');
    });

    test('kullanıcı kendi listesinde müşteri alanı boş kalır', () {
      final siparis = Siparis.fromJson({
        'id': 8,
        'totalAmount': '100.00',
        'status': 'PAID',
        'addressText': 'Test adresi, Eyupsultan/Istanbul',
        'createdAt': '2026-09-04T08:00:00.000Z',
        'items': [],
      });

      expect(siparis.musteri, isNull);
    });
  });

  group('Dogrulayicilar - ödeme', () {
    test('Luhn kontrol hanesi tutmayan numara reddedilir', () {
      expect(Dogrulayicilar.kartNumarasi('4242 4242 4242 4242'), isNull);
      expect(Dogrulayicilar.kartNumarasi('4242 4242 4242 4241'), isNotNull);
    });

    test('16 haneden kısa numara reddedilir', () {
      expect(Dogrulayicilar.kartNumarasi('4242 4242'), isNotNull);
      expect(Dogrulayicilar.kartNumarasi(''), isNotNull);
    });

    test('son kullanma biçimi ve geçmiş tarih denetlenir', () {
      expect(Dogrulayicilar.sonKullanma('1228'), isNotNull);
      expect(Dogrulayicilar.sonKullanma('13/28'), isNotNull);
      expect(Dogrulayicilar.sonKullanma('01/24'), isNotNull);
      expect(Dogrulayicilar.sonKullanma('12/99'), isNull);
    });

    test('cvv 3 hane olmalıdır', () {
      expect(Dogrulayicilar.cvv('12'), isNotNull);
      expect(Dogrulayicilar.cvv('1234'), isNotNull);
      expect(Dogrulayicilar.cvv('123'), isNull);
    });

    test('adres en az 10 karakter olmalıdır', () {
      expect(Dogrulayicilar.adres('Kadikoy'), isNotNull);
      expect(Dogrulayicilar.adres('Güzeltepe Mahallesi No 7'), isNull);
    });
  });

  group('Dogrulayicilar - ürün formu', () {
    test('fiyat en fazla iki ondalıklı olmalı, virgül kabul edilmez', () {
      // Sunucu `^\d+(\.\d{1,2})?$` deseniyle denetliyor; virgüllü
      // değer oraya gidince reddedilirdi.
      expect(Dogrulayicilar.fiyat('1499.90'), isNull);
      expect(Dogrulayicilar.fiyat('0'), isNull);
      expect(Dogrulayicilar.fiyat('1499,90'), isNotNull);
      expect(Dogrulayicilar.fiyat('1499.905'), isNotNull);
      expect(Dogrulayicilar.fiyat('-5'), isNotNull);
      expect(Dogrulayicilar.fiyat(''), isNotNull);
    });

    test('stok negatif olamaz, ondalık olamaz', () {
      expect(Dogrulayicilar.stok('0'), isNull);
      expect(Dogrulayicilar.stok('25'), isNull);
      expect(Dogrulayicilar.stok('-1'), isNotNull);
      expect(Dogrulayicilar.stok('2.5'), isNotNull);
      expect(Dogrulayicilar.stok(''), isNotNull);
    });

    test('ürün adı ve açıklama sunucudaki sınırlarla aynı', () {
      expect(Dogrulayicilar.urunAdi('Oyuncu Faresi'), isNull);
      expect(Dogrulayicilar.urunAdi(''), isNotNull);
      expect(Dogrulayicilar.urunAdi('a' * 201), isNotNull);

      expect(Dogrulayicilar.urunAciklamasi('Kısa açıklama'), isNull);
      expect(Dogrulayicilar.urunAciklamasi('a' * 2001), isNotNull);
    });
  });

  group('KartNumarasiBicimi', () {
    TextEditingValue yaz(String metin, int imlec) => TextEditingValue(
      text: metin,
      selection: TextSelection.collapsed(offset: imlec),
    );

    test('16 hane dörderli gruplanır', () {
      final sonuc = KartNumarasiBicimi()
          .formatEditUpdate(TextEditingValue.empty, yaz('4242424242424242', 16));

      expect(sonuc.text, '4242 4242 4242 4242');
      expect(sonuc.selection.baseOffset, 19);
    });

    // Öykünücüde bulunan hata: alanın ortasındaki bir hane düzeltilmek
    // istendiğinde imleç metnin sonuna atılıyor, yazılan rakam sona
    // ekleniyor ve numara karışıyordu. İmleç, önünde kaç rakam varsa yine
    // o kadar rakamın arkasında kalmalı.
    //
    // Beklenen konum 15 değil 14: imleç ayracın ÖNÜNDE kalır. Ayracın
    // arkasına geçseydi, bir sonraki geri tuşu rakamı değil boşluğu silerdi;
    // boşluk da hemen yeniden üretildiği için geri tuşu ölü görünürdü.
    test('ortadaki hane silinince imleç yerinde kalır, sona atlamaz', () {
      final sonuc = KartNumarasiBicimi().formatEditUpdate(
        yaz('4242 4242 4242 4241', 16),
        yaz('4242 4242 4242 241', 15),
      );

      expect(sonuc.text, '4242 4242 4242 241');
      expect(sonuc.selection.baseOffset, 14);
      expect(sonuc.selection.baseOffset, isNot(sonuc.text.length));
    });

    test('boşluklar kullanıcıdan gelse bile yeniden üretilir', () {
      final sonuc = KartNumarasiBicimi()
          .formatEditUpdate(TextEditingValue.empty, yaz('42 4242', 7));

      expect(sonuc.text, '4242 42');
    });
  });

  group('SonKullanmaBicimi', () {
    test('iki haneden sonra bölü işareti konur', () {
      final sonuc = SonKullanmaBicimi().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1228',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );

      expect(sonuc.text, '12/28');
      expect(sonuc.selection.baseOffset, 5);
    });

    test('tek hane girildiğinde bölü eklenmez', () {
      final sonuc = SonKullanmaBicimi().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );

      expect(sonuc.text, '1');
    });
  });
}
