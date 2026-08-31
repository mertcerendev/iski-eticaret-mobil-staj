import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/core/dogrulayicilar.dart';
import 'package:mobile/models/kategori.dart';
import 'package:mobile/models/sayfali_sonuc.dart';
import 'package:mobile/models/sepet.dart';
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
}
