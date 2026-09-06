import 'package:flutter/material.dart';

/// Simge ve yazıdan oluşan bölüm başlığı.
///
/// Ödeme ekranında kartsız, [BilgiKarti] içinde kartlı kullanılıyor; bu
/// yüzden karttan ayrı duruyor.
class BolumBasligi extends StatelessWidget {
  final String baslik;
  final IconData simge;

  const BolumBasligi({super.key, required this.baslik, required this.simge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(simge, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          baslik,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Başlıklı kart: üstte [BolumBasligi], altında serbest içerik.
///
/// Aynı kabuk üç ekranda ayrı ayrı yazılmıştı — profil düzenlemedeki
/// bölümler, sipariş detayındaki bilgi blokları ve ödeme ekranının
/// başlıkları. Üçü de birebir aynıydı, tek fark başlıkla içerik arasındaki
/// birkaç pikseldi; o fark da bir anlam taşımadığı için tek değerde
/// birleştirildi.
class BilgiKarti extends StatelessWidget {
  final String baslik;
  final IconData simge;
  final Widget child;

  const BilgiKarti({
    super.key,
    required this.baslik,
    required this.simge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BolumBasligi(baslik: baslik, simge: simge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
