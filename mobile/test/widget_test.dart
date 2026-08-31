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
      expect(sonuc.sonSayfaMi, isFalse); // 1. sayfa, toplam 2 sayfa
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
