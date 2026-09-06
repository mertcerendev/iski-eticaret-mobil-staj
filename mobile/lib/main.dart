import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/favori_provider.dart';
import 'providers/sepet_provider.dart';
import 'providers/siparis_provider.dart';
import 'providers/urun_provider.dart';
import 'providers/yonetici_siparis_provider.dart';
import 'screens/ana_kabuk.dart';

void main() {
  runApp(const UygulamaKoku());
}

class UygulamaKoku extends StatelessWidget {
  const UygulamaKoku({super.key});

  @override
  Widget build(BuildContext context) {
    // Sağlayıcılar en tepede kurulur: altındaki her ekran bu durumlara
    // ulaşabilir, ekrandan ekrana parametre taşımaya gerek kalmaz.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..acilistaKontrolEt(),
        ),
        // Ürün listesi giriş ekranında da bellekte durur ama isteği
        // ancak ana ekran açıldığında atar.
        ChangeNotifierProvider(create: (_) => UrunProvider()),
        ChangeNotifierProvider(create: (_) => FavoriProvider()),
        ChangeNotifierProvider(create: (_) => SepetProvider()),

        // Sipariş geçmişi yalnızca profil sekmesinden açılıyor ama
        // sağlayıcı burada kuruluyor: sipariş verildikten sonra listenin
        // tazelenmesi gerekiyor ve o iş ödeme ekranından tetikleniyor.
        ChangeNotifierProvider(create: (_) => SiparisProvider()),

        // Yönetici sipariş listesi ayrı tutuluyor: kullanıcının kendi
        // geçmişiyle farklı veri kümeleri.
        ChangeNotifierProvider(create: (_) => YoneticiSiparisProvider()),
      ],
      child: MaterialApp(
        title: 'Nuvia',
        debugShowCheckedModeBanner: false,
        theme: UygulamaTemasi.acik,
        home: const OturumKapisi(),
      ),
    );
  }
}

/// Açılışta kayıtlı token denetlenirken karşılama ekranını, denetim
/// bitince uygulamayı gösterir.
///
/// **Gün 21'de değişti.** Önceden oturum yoksa doğrudan giriş ekranı
/// açılıyordu. Oysa ürün ve kategori uçları sunucuda herkese açık:
/// vitrini görmek için hesap istemek, mağazanın kapısına kilit takmak
/// gibiydi. Artık uygulama her hâlükârda ürünlerle açılıyor; giriş
/// yalnızca sepet, favori ve sipariş gibi hesaba bağlı işlemlerde
/// isteniyor.
class OturumKapisi extends StatelessWidget {
  const OturumKapisi({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<AuthProvider>().durum;

    // Bekleme kısa: kayıtlı token varsa sunucuya bir istek atılıyor.
    // Bu sırada ürün listesi gösterilseydi, oturum açık çıktığında
    // ekran bir kez daha kurulurdu.
    if (durum == OturumDurumu.kontrolEdiliyor) return const _AcilisEkrani();

    return const AnaKabuk();
  }
}

class _AcilisEkrani extends StatelessWidget {
  const _AcilisEkrani();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/marka/logo.png', width: 200),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
