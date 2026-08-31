import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/api_constants.dart';
import '../models/sepet.dart';
import '../providers/sepet_provider.dart';
import '../widgets/adet_secici.dart';
import '../widgets/durum_gorunumleri.dart';
import 'odeme_ekrani.dart';

class SepetEkrani extends StatelessWidget {
  const SepetEkrani({super.key});

  /// Sunucunun bir üründen izin verdiği en yüksek adet. Detay ekranındaki
  /// sınırın aynısı; kullanıcı reddedilecek istek göndermesin.
  static const int _enFazlaAdet = 20;

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<SepetProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sepetim')),
      body: _icerik(context, saglayici),

      // Toplam şeridi listeyle birlikte kaymaz, altta sabit durur; kullanıcı
      // uzun sepette de tutarı görmek için sona kaydırmak zorunda kalmaz.
      // Bu Scaffold alt gezinme çubuğunun içinde olduğu için şerit onun
      // hemen üstüne oturur.
      bottomNavigationBar: saglayici.sepet.bosMu
          ? null
          : _ToplamSeridi(sepet: saglayici.sepet),
    );
  }

  Widget _icerik(BuildContext context, SepetProvider saglayici) {
    if (saglayici.yukleniyor && saglayici.sepet.bosMu) {
      return const YukleniyorGorunumu();
    }

    if (saglayici.hata != null && saglayici.sepet.bosMu) {
      return HataGorunumu(mesaj: saglayici.hata!, onTekrarDene: saglayici.yukle);
    }

    if (saglayici.sepet.bosMu) {
      return const BosGorunumu(
        baslik: 'Sepetiniz boş',
        aciklama:
            'Ürünler sekmesinden beğendiğiniz ürünleri sepetinize ekleyebilirsiniz.',
      );
    }

    return RefreshIndicator(
      onRefresh: saglayici.yukle,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: saglayici.sepet.satirlar.length,
        itemBuilder: (context, sira) {
          final satir = saglayici.sepet.satirlar[sira];

          // `Dismissible` parmakla yana kaydırınca satırı listeden çıkarır.
          // Anahtar ürün kimliğinden üretilir; sıra numarası kullanılsaydı
          // silme sonrası kayan satırlar birbirine karışırdı.
          return Dismissible(
            key: ValueKey(satir.urunId),
            direction: DismissDirection.endToStart,
            background: const _SilmeZemini(),
            confirmDismiss: (_) => _silmeyiOnayla(context, satir),
            child: _SepetSatiriKarti(satir: satir, enFazlaAdet: _enFazlaAdet),
          );
        },
      ),
    );
  }

  /// Kaydırma silmeyi kendiliğinden yapmaz; önce onay alınır, sonra sunucuya
  /// gidilir. Sunucu reddederse `false` döner ve satır yerinde kalır.
  Future<bool> _silmeyiOnayla(BuildContext context, SepetSatiri satir) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (pencere) => AlertDialog(
        title: const Text('Ürün çıkarılsın mı?'),
        content: Text('"${satir.urun.ad}" sepetinizden çıkarılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(pencere).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(pencere).pop(true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (onay != true || !context.mounted) return false;

    final hata = await context.read<SepetProvider>().cikar(satir.urunId);

    if (!context.mounted) return false;

    if (hata != null) {
      _uyariGoster(context, hata, basarili: false);
      return false;
    }

    return true;
  }
}

void _uyariGoster(BuildContext context, String mesaj, {required bool basarili}) {
  final mesajci = ScaffoldMessenger.of(context);

  mesajci.hideCurrentSnackBar();
  mesajci.showSnackBar(
    SnackBar(
      content: Text(mesaj),
      backgroundColor: basarili
          ? Colors.green.shade700
          : Theme.of(context).colorScheme.error,
    ),
  );
}

class _SepetSatiriKarti extends StatelessWidget {
  final SepetSatiri satir;
  final int enFazlaAdet;

  const _SepetSatiriKarti({required this.satir, required this.enFazlaAdet});

  /// Artı düğmesinin durabileceği en yüksek değer: stok ile üst sınırın küçüğü.
  int get _tavan =>
      satir.urun.stok < enFazlaAdet ? satir.urun.stok : enFazlaAdet;

  @override
  Widget build(BuildContext context) {
    // Yalnız bu satırın kilit durumu dinlenir; başka bir satır güncellenince
    // bu kart yeniden çizilmez.
    final islemde = context.select<SepetProvider, bool>(
      (saglayici) => saglayici.islemdeMi(satir.urunId),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: _SatirGorseli(adres: satir.urun.gorselUrl),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        satir.urun.ad,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${satir.urun.fiyatMetni} × ${satir.adet}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        satir.araToplamMetni,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!satir.satinAlinabilir) ...[
              const SizedBox(height: 8),
              _Uyari(durum: satir.urun.stokMetni),
            ],

            const SizedBox(height: 6),

            Row(
              children: [
                AdetSecici(
                  adet: satir.adet,
                  tavan: _tavan,
                  etkin: !islemde,
                  onDegisti: (yeniAdet) =>
                      _adediDegistir(context, yeniAdet),
                ),
                const Spacer(),

                if (islemde)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Sepetten çıkar',
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.grey.shade600,
                    onPressed: () => _cikar(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _adediDegistir(BuildContext context, int yeniAdet) async {
    final hata = await context.read<SepetProvider>().adetDegistir(
      urunId: satir.urunId,
      adet: yeniAdet,
    );

    if (hata != null && context.mounted) {
      _uyariGoster(context, hata, basarili: false);
    }
  }

  Future<void> _cikar(BuildContext context) async {
    final hata = await context.read<SepetProvider>().cikar(satir.urunId);

    if (!context.mounted) return;

    _uyariGoster(
      context,
      hata ?? 'Ürün sepetten çıkarıldı.',
      basarili: hata == null,
    );
  }
}

/// Stoğu tükenen ya da satıştan kaldırılan satır için uyarı şeridi.
class _Uyari extends StatelessWidget {
  final String durum;

  const _Uyari({required this.durum});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade800),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Bu ürün şu an alınamıyor ($durum). Toplama dâhil edilmedi.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SatirGorseli extends StatelessWidget {
  final String? adres;

  const _SatirGorseli({required this.adres});

  @override
  Widget build(BuildContext context) {
    final tamAdres = ApiSabitleri.tamGorselAdresi(adres);

    Widget yerTutucu() => Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
    );

    if (tamAdres.isEmpty) return yerTutucu();

    return CachedNetworkImage(
      imageUrl: tamAdres,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: Colors.grey.shade200),
      errorWidget: (_, _, _) => yerTutucu(),
    );
  }
}

/// Sola kaydırıldığında arkadan görünen kırmızı silme zemini.
class _SilmeZemini extends StatelessWidget {
  const _SilmeZemini();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(right: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

class _ToplamSeridi extends StatelessWidget {
  final Sepet sepet;

  const _ToplamSeridi({required this.sepet});

  /// Alınamayan satırlar (stoğu tükenmiş ya da satıştan kaldırılmış) siparişi
  /// tümden engeller: sunucu böyle bir satır görünce işlemi geri alıyor.
  /// Kullanıcı bunu ödeme formunu doldurduktan sonra değil, burada öğrenmeli.
  bool get _siparisVerilebilir =>
      sepet.satirlar.every((satir) => satir.satinAlinabilir);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sepet.satirlar.length} üründe ${sepet.toplamAdet} adet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Toplam',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  sepet.toplamMetni,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            FilledButton.icon(
              onPressed: _siparisVerilebilir
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OdemeEkrani()),
                      )
                  : null,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Siparişi Tamamla'),
            ),

            if (!_siparisVerilebilir) ...[
              const SizedBox(height: 8),
              Text(
                'Alınamayan ürünleri sepetten çıkarmadan sipariş verilemez.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
