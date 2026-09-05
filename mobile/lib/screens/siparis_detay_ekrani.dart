import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../core/theme/app_theme.dart';
import '../models/siparis.dart';
import '../providers/siparis_provider.dart';
import '../widgets/durum_gorunumleri.dart';
import '../widgets/siparis_durum_rozeti.dart';
import '../widgets/urun_gorseli.dart';

/// Tek siparişin tüm ayrıntısı: durum, tarih, ödeme, adres ve kalemler.
///
/// Ekran siparişin kendisini değil **kimliğini** alıyor ve kaydı her çizimde
/// sağlayıcıdan okuyor. Nesne parametre olarak taşınsaydı, aşağı çekip
/// yenilemeden sonra listedeki kayıt güncellenir ama buradaki kopya eski
/// kalırdı — iki ayrı doğruluk kaynağı doğardı.
class SiparisDetayEkrani extends StatelessWidget {
  final int siparisId;

  const SiparisDetayEkrani({super.key, required this.siparisId});

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<SiparisProvider>();
    final siparis = saglayici.bul(siparisId);

    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Detayı')),
      body: siparis == null
          // Liste bu arada temizlenmişse kayıt bulunamaz. Boş ekran yerine
          // kullanıcıya ne olduğunu anlatan bir görünüm veriliyor.
          ? const BosGorunumu(
              baslik: 'Sipariş bulunamadı',
              aciklama: 'Bu sipariş listeden kaldırılmış olabilir.',
            )
          : _Govde(siparis: siparis),
    );
  }
}

class _Govde extends StatelessWidget {
  final Siparis siparis;

  const _Govde({required this.siparis});

  /// Aşağı çekince siparişin son durumunu sunucudan çeker.
  ///
  /// Durum yönetici tarafından değiştirilebildiği için (hazırlanıyor, kargoda)
  /// kullanıcının elindeki kayıt bayatlayabiliyor.
  Future<void> _yenile(BuildContext context) async {
    final bildir = Bildirim(context);

    final hata = await context.read<SiparisProvider>().detayYenile(siparis.id);

    if (hata != null) bildir.hata(hata);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _yenile(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BaslikKarti(siparis: siparis),
          const SizedBox(height: 14),

          _BilgiKarti(
            baslik: 'Teslimat Adresi',
            simge: Icons.local_shipping_outlined,
            child: Text(
              siparis.adres,
              style: TextStyle(height: 1.4, color: Colors.grey.shade800),
            ),
          ),
          const SizedBox(height: 14),

          _BilgiKarti(
            baslik: 'Ödeme',
            simge: Icons.credit_card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(siparis.kartMetni),
                if (siparis.kartSahibi != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    siparis.kartSahibi!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          _BilgiKarti(
            baslik: 'Ürünler (${siparis.toplamAdet} adet)',
            simge: Icons.inventory_2_outlined,
            child: Column(
              children: [
                for (final kalem in siparis.kalemler) ...[
                  const Divider(height: 20),
                  _KalemSatiri(kalem: kalem),
                ],
                const Divider(height: 20),
                Row(
                  children: [
                    const Text(
                      'Toplam',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      siparis.toplamMetni,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UygulamaTemasi.vurgu,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Durumu güncellemek için listeyi aşağı çekin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}

class _BaslikKarti extends StatelessWidget {
  final Siparis siparis;

  const _BaslikKarti({required this.siparis});

  @override
  Widget build(BuildContext context) {
    // Yalnız bu siparişin yenileme durumu dinleniyor.
    final yenileniyor = context.select<SiparisProvider, bool>(
      (saglayici) => saglayici.yenileniyorMu(siparis.id),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  siparis.numara,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (yenileniyor)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  SiparisDurumRozeti(durum: siparis.durum, buyuk: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              siparis.tarihMetni,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Başlık, simge ve serbest içerikten oluşan ortak kart kabuğu.
/// Detaydaki üç bölüm de aynı düzeni kullanıyor.
class _BilgiKarti extends StatelessWidget {
  final String baslik;
  final IconData simge;
  final Widget child;

  const _BilgiKarti({
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
            Row(
              children: [
                Icon(
                  simge,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: UrunGorseli(adres: kalem.gorselUrl, simgeBoyutu: 20),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kalem.urunAd, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 3),
              // Birim fiyat ürünün bugünkü fiyatı değil, sipariş anında
              // dondurulan fiyattır.
              Text(
                '${kalem.birimFiyatMetni} × ${kalem.adet}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        Text(
          kalem.araToplamMetni,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
