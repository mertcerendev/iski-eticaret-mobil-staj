import 'package:flutter/material.dart';

import '../models/siparis.dart';

/// Sipariş oluştuktan sonra gösterilen onay ekranı.
///
/// Sipariş numarası, tutar, teslimat adresi ve ödemede kullanılan kartın son
/// dört hanesi burada gösterilir. Sipariş geçmişi ekranı Gün 13'te
/// eklenecek; şimdilik kullanıcı siparişini yalnızca bu ekranda görüyor.
class SiparisBasariliEkrani extends StatelessWidget {
  final Siparis siparis;

  const SiparisBasariliEkrani({super.key, required this.siparis});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      // Geri oku gizli: sipariş verildikten sonra geri dönülecek bir yer yok,
      // tek çıkış aşağıdaki düğme.
      appBar: AppBar(
        title: const Text('Siparişiniz Alındı'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.check_circle,
            size: 76,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 16),

          Text(
            siparis.numara,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Siparişiniz alındı ve ödemesi tamamlandı.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Satir(baslik: 'Durum', deger: siparis.durum.etiket),
                  _Satir(baslik: 'Tarih', deger: siparis.tarihMetni),
                  _Satir(baslik: 'Ödeme', deger: siparis.kartMetni),
                  _Satir(
                    baslik: 'Tutar',
                    deger: siparis.toplamMetni,
                    vurgulu: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teslimat Adresi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    siparis.adres,
                    style: TextStyle(height: 1.4, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ürünler (${siparis.toplamAdet} adet)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  for (final kalem in siparis.kalemler) ...[
                    const Divider(height: 18),
                    _KalemSatiri(kalem: kalem),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            // Yığındaki bütün ekranlar kapatılıp kabuğa dönülüyor; kullanıcı
            // geri tuşuyla ödeme akışına geri düşmemeli.
            onPressed: () =>
                Navigator.of(context).popUntil((rota) => rota.isFirst),
            icon: const Icon(Icons.storefront),
            label: const Text('Alışverişe Devam Et'),
          ),
          const SizedBox(height: 12),

          Text(
            'Siparişinizin hazırlanma durumunu daha sonra takip edebileceksiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: tema.hintColor),
          ),
        ],
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  final String baslik;
  final String deger;
  final bool vurgulu;

  const _Satir({
    required this.baslik,
    required this.deger,
    this.vurgulu = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(baslik, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(
            deger,
            style: TextStyle(
              fontWeight: vurgulu ? FontWeight.bold : FontWeight.w500,
              fontSize: vurgulu ? 17 : 14,
              color: vurgulu ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _KalemSatiri extends StatelessWidget {
  final SiparisKalemi kalem;

  const _KalemSatiri({required this.kalem});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kalem.urunAd, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              // Birim fiyat, ürünün bugünkü fiyatı değil sipariş anında
              // dondurulan fiyattır.
              Text(
                '${kalem.birimFiyatMetni} × ${kalem.adet}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          kalem.araToplamMetni,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
