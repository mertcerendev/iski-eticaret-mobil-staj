import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/ana_ekran.dart';
import 'screens/giris_ekrani.dart';

void main() {
  runApp(const UygulamaKoku());
}

class UygulamaKoku extends StatelessWidget {
  const UygulamaKoku({super.key});

  @override
  Widget build(BuildContext context) {
    // Sağlayıcı en tepede kurulur: altındaki her ekran oturum bilgisine
    // ulaşabilir, ekrandan ekrana parametre taşımaya gerek kalmaz.
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..acilistaKontrolEt(),
      child: MaterialApp(
        title: 'İSKİ E-Ticaret',
        debugShowCheckedModeBanner: false,
        theme: UygulamaTemasi.acik,
        home: const OturumKapisi(),
      ),
    );
  }
}

/// Oturum durumuna göre hangi ekranın açılacağına karar verir.
///
/// Giriş ve kayıt ekranları başarı sonrası elle yönlendirme yapmaz;
/// durumu değiştirirler, karar tek yerde — burada — verilir.
class OturumKapisi extends StatelessWidget {
  const OturumKapisi({super.key});

  @override
  Widget build(BuildContext context) {
    final durum = context.watch<AuthProvider>().durum;

    switch (durum) {
      // Açılışta kayıtlı token sunucuya sorulurken kısa bir bekleme olur.
      case OturumDurumu.kontrolEdiliyor:
        return const _AcilisEkrani();

      case OturumDurumu.cikisYapildi:
        return const GirisEkrani();

      case OturumDurumu.girisYapildi:
        return const AnaEkran();
    }
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
            Icon(
              Icons.storefront,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
