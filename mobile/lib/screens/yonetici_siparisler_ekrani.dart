import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../models/siparis.dart';
import '../providers/yonetici_siparis_provider.dart';
import '../widgets/durum_gorunumleri.dart';
import '../widgets/siparis_durum_rozeti.dart';

/// Yöneticinin bütün siparişleri görüp durumlarını ilerlettiği ekran.
///
/// Kullanıcının kendi geçmişinden iki farkı var: müşteri bilgisi gösteriliyor
/// ve her siparişin durumu değiştirilebiliyor.
class YoneticiSiparislerEkrani extends StatefulWidget {
  const YoneticiSiparislerEkrani({super.key});

  @override
  State<YoneticiSiparislerEkrani> createState() =>
      _YoneticiSiparislerEkraniDurumu();
}

class _YoneticiSiparislerEkraniDurumu
    extends State<YoneticiSiparislerEkrani> {
  final _kaydirmaDenetleyici = ScrollController();

  /// Liste sonuna bu kadar piksel kala sonraki sayfa isteniyor.
  static const double _yuklemeEsigi = 300;

  @override
  void initState() {
    super.initState();

    _kaydirmaDenetleyici.addListener(_kaydirmayiDinle);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<YoneticiSiparisProvider>().yukle();
    });
  }

  @override
  void dispose() {
    _kaydirmaDenetleyici.dispose();
    super.dispose();
  }

  void _kaydirmayiDinle() {
    final konum = _kaydirmaDenetleyici.position;

    if (konum.pixels >= konum.maxScrollExtent - _yuklemeEsigi) {
      context.read<YoneticiSiparisProvider>().dahaFazlaYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<YoneticiSiparisProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Yönetimi')),
      body: Column(
        children: [
          _DurumSuzgeci(
            secili: saglayici.durumSuzgeci,
            onSecildi: saglayici.suzgecSec,
          ),
          if (!saglayici.bosMu)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Text(
                    '${saglayici.toplam} sipariş',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _icerik(saglayici)),
        ],
      ),
    );
  }

  Widget _icerik(YoneticiSiparisProvider saglayici) {
    if (saglayici.yukleniyor && saglayici.bosMu) {
      return const YukleniyorGorunumu();
    }

    if (saglayici.hata != null && saglayici.bosMu) {
      return HataGorunumu(mesaj: saglayici.hata!, onTekrarDene: saglayici.yukle);
    }

    if (saglayici.bosMu) {
      return BosGorunumu(
        baslik: 'Sipariş bulunamadı',
        aciklama: saglayici.durumSuzgeci == null
            ? 'Henüz hiç sipariş verilmemiş.'
            : 'Bu durumda sipariş yok. Süzgeci değiştirmeyi deneyin.',
      );
    }

    return RefreshIndicator(
      onRefresh: saglayici.yukle,
      child: ListView.builder(
        controller: _kaydirmaDenetleyici,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: saglayici.siparisler.length,
        itemBuilder: (context, sira) {
          return _YoneticiSiparisKarti(siparis: saglayici.siparisler[sira]);
        },
      ),
    );
  }
}

/// Duruma göre süzen yatay çip şeridi.
class _DurumSuzgeci extends StatelessWidget {
  final SiparisDurumu? secili;
  final ValueChanged<SiparisDurumu?> onSecildi;

  const _DurumSuzgeci({required this.secili, required this.onSecildi});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        children: [
          // "Tümü" ayrı bir durum değil, süzgecin kaldırılması.
          FilterChip(
            label: const Text('Tümü'),
            selected: secili == null,
            onSelected: (_) => onSecildi(null),
          ),
          const SizedBox(width: 8),

          for (final durum in SiparisDurumu.values) ...[
            FilterChip(
              label: Text(durum.etiket),
              selected: secili == durum,
              onSelected: (secildi) => onSecildi(secildi ? durum : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _YoneticiSiparisKarti extends StatelessWidget {
  final Siparis siparis;

  const _YoneticiSiparisKarti({required this.siparis});

  Future<void> _durumDegistir(
    BuildContext context,
    SiparisDurumu yeni,
  ) async {
    final bildir = Bildirim(context);

    final hata = await context
        .read<YoneticiSiparisProvider>()
        .durumDegistir(siparis.id, yeni);

    bildir.sonuc(hata, '${siparis.numara} → ${yeni.etiket}');
  }

  @override
  Widget build(BuildContext context) {
    final guncelleniyor = context.select<YoneticiSiparisProvider, bool>(
      (saglayici) => saglayici.guncelleniyorMu(siparis.id),
    );

    final sonrakiler = siparis.durum.sonrakiler;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  siparis.numara,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (guncelleniyor)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  SiparisDurumRozeti(durum: siparis.durum),
              ],
            ),
            const SizedBox(height: 6),

            // Müşteri bilgisi yalnızca bu ekranda var; sunucu kullanıcının
            // kendi listesinde göndermiyor.
            if (siparis.musteri != null)
              Text(
                '${siparis.musteri!.adSoyad} · ${siparis.musteri!.eposta}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),

            Text(
              siparis.tarihMetni,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  '${siparis.kalemler.length} üründe '
                  '${siparis.toplamAdet} adet',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  siparis.toplamMetni,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            // Sonu gelmiş siparişte (teslim edildi / iptal) düğme çizilmiyor;
            // sunucudaki geçiş tablosu da bu durumlardan çıkışa izin vermiyor.
            if (sonrakiler.isNotEmpty) ...[
              const Divider(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final sonraki in sonrakiler)
                    OutlinedButton.icon(
                      onPressed: guncelleniyor
                          ? null
                          : () => _durumDegistir(context, sonraki),
                      icon: const Icon(Icons.arrow_forward, size: 15),
                      label: Text(sonraki.etiket),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
