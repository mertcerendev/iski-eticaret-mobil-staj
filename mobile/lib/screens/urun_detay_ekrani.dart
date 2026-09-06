import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../core/theme/app_theme.dart';
import '../models/urun.dart';
import '../providers/auth_provider.dart';
import '../providers/sepet_provider.dart';
import '../providers/urun_provider.dart';
import '../widgets/adet_secici.dart';
import '../widgets/favori_dugmesi.dart';
import '../widgets/urun_gorseli.dart';
import 'giris_ekrani.dart';
import 'urun_formu_ekrani.dart';

class UrunDetayEkrani extends StatefulWidget {
  final Urun urun;

  /// Geçiş animasyonunun eşleşeceği kartın sekmesi. Karttaki etiketle
  /// birebir aynı olmak zorunda, yoksa görsel büyüyerek gelmez.
  final String heroOneki;

  const UrunDetayEkrani({
    super.key,
    required this.urun,
    required this.heroOneki,
  });

  @override
  State<UrunDetayEkrani> createState() => _UrunDetayEkraniDurumu();
}

class _UrunDetayEkraniDurumu extends State<UrunDetayEkrani> {
  /// Sunucu bir üründen en fazla 20 adet alınmasına izin veriyor. Aynı sınır
  /// burada da uygulanır ki kullanıcı reddedilecek bir istek göndermesin.
  static const int _enFazlaAdet = 20;

  int _adet = 1;

  Urun get _urun => widget.urun;

  /// Seçilebilecek en yüksek adet: stok ile üst sınırın küçüğü.
  int get _adetTavani =>
      _urun.stok < _enFazlaAdet ? _urun.stok : _enFazlaAdet;

  /// Ekleme isteği doğrudan servise değil sağlayıcıya gidiyor. Sağlayıcı
  /// sunucudan dönen yeni sepeti sakladığı için alt gezinmedeki rozet
  /// aynı anda güncelleniyor; ekranın rozeti ayrıca haberdar etmesi gerekmiyor.
  Future<void> _sepeteEkle() async {
    // Sepet ucu sunucuda oturum istiyor; misafir önce giriş ekranına
    // yönlendiriliyor.
    if (!await oturumGerekli(
      context,
      'Ürünleri sepete eklemek için hesabınıza giriş yapın.',
    )) {
      return;
    }

    if (!mounted) return;

    final hata = await context.read<SepetProvider>().ekle(
      urunId: _urun.id,
      adet: _adet,
    );

    if (!mounted) return;

    Bildirim(context).sonuc(hata, '$_adet adet sepete eklendi.');
  }

  /// Formu açar; kaydedildiyse bu ekran da kapatılır.
  ///
  /// Ekrandaki [Urun] nesnesi listeden parametre olarak geldiği için
  /// güncellemeden sonra bayatlıyor. Kaydı yeniden çekmek yerine ekran
  /// kapatılıyor: kullanıcı zaten tazelenmiş listeye dönüyor.
  Future<void> _duzenle() async {
    final yonlendirici = Navigator.of(context);

    final kaydedildi = await yonlendirici.push<bool>(
      MaterialPageRoute(builder: (_) => UrunFormuEkrani(urun: _urun)),
    );

    if (kaydedildi == true && mounted) yonlendirici.pop();
  }

  Future<void> _sil() async {
    final saglayici = context.read<UrunProvider>();
    final yonlendirici = Navigator.of(context);
    final bildir = Bildirim(context);

    final onay = await showDialog<bool>(
      context: context,
      builder: (pencere) => AlertDialog(
        title: const Text('Ürün satıştan kaldırılsın mı?'),
        // Sunucuda kayıt gerçekten silinmiyor; geçmiş siparişler bu ürüne
        // bağlı olduğu için yalnızca pasife alınıyor. Metin de bunu söylüyor.
        content: Text(
          '"${_urun.ad}" listeden kaldırılacak. '
          'Geçmiş siparişlerdeki kaydı korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(pencere).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(pencere).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    final hata = await saglayici.urunSil(_urun.id);

    if (!mounted) return;

    if (hata != null) {
      bildir.hata(hata);
      return;
    }

    yonlendirici.pop();
  }

  @override
  Widget build(BuildContext context) {
    final ekleniyor = context.select<SepetProvider, bool>(
      (saglayici) => saglayici.islemdeMi(_urun.id),
    );

    final yoneticiMi = context.watch<AuthProvider>().yoneticiMi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
          if (yoneticiMi) ...[
            IconButton(
              tooltip: 'Düzenle',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _duzenle,
            ),
            IconButton(
              tooltip: 'Satıştan kaldır',
              icon: const Icon(Icons.delete_outline),
              onPressed: _sil,
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FavoriDugmesi(urun: _urun, renk: Colors.white),
          ),
        ],
      ),
      body: ListView(
        children: [
          // `Hero`, aynı etiketi taşıyan iki widget arasında geçiş
          // animasyonu kurar: karttaki görsel büyüyerek detay görselinin
          // yerine oturur. Etiket ürün kimliğiyle benzersizleştirilir.
          Hero(
            tag: '${widget.heroOneki}-urun-gorsel-${_urun.id}',
            child: AspectRatio(
              aspectRatio: 1,
              child: UrunGorseli(adres: _urun.gorselUrl, simgeBoyutu: 64),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_urun.kategori != null)
                  Text(
                    _urun.kategori!.ad,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 6),

                Text(
                  _urun.ad,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  _urun.fiyatMetni,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: UygulamaTemasi.vurgu,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),

                _StokDurumu(urun: _urun),
                const SizedBox(height: 24),

                const Text(
                  'Ürün Açıklaması',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                Text(
                  _urun.aciklama,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 28),

                if (_urun.stoktaVar) ...[
                  Row(
                    children: [
                      const Text(
                        'Adet',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      AdetSecici(
                        adet: _adet,
                        tavan: _adetTavani,
                        onDegisti: (yeni) => setState(() => _adet = yeni),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  // Stok yoksa buton pasif. Nedeni hemen altında yazıyor ki
                  // kullanıcı butonun neden çalışmadığını anlasın.
                  onPressed:
                      (!_urun.stoktaVar || ekleniyor) ? null : _sepeteEkle,
                  icon: ekleniyor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_shopping_cart),
                  label: Text(_urun.stoktaVar ? 'Sepete Ekle' : 'Tükendi'),
                ),

                if (!_urun.stoktaVar) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Bu ürünün stoğu tükendiği için sepete eklenemiyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StokDurumu extends StatelessWidget {
  final Urun urun;

  const _StokDurumu({required this.urun});

  @override
  Widget build(BuildContext context) {
    final renk = !urun.stoktaVar
        ? Colors.red.shade700
        : urun.sonUrunler
            ? Colors.orange.shade800
            : Colors.green.shade700;

    return Row(
      children: [
        Icon(
          urun.stoktaVar ? Icons.check_circle_outline : Icons.remove_circle_outline,
          size: 18,
          color: renk,
        ),
        const SizedBox(width: 6),
        Text(
          urun.stokMetni,
          style: TextStyle(color: renk, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
