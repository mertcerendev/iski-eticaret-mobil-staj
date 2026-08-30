import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/urun.dart';
import '../services/sepet_service.dart';
import '../widgets/favori_dugmesi.dart';

class UrunDetayEkrani extends StatefulWidget {
  final Urun urun;

  const UrunDetayEkrani({super.key, required this.urun});

  @override
  State<UrunDetayEkrani> createState() => _UrunDetayEkraniDurumu();
}

class _UrunDetayEkraniDurumu extends State<UrunDetayEkrani> {
  final SepetServisi _sepetServisi = SepetServisi();

  /// Sunucu bir üründen en fazla 20 adet alınmasına izin veriyor. Aynı sınır
  /// burada da uygulanır ki kullanıcı reddedilecek bir istek göndermesin.
  static const int _enFazlaAdet = 20;

  int _adet = 1;
  bool _ekleniyor = false;

  Urun get _urun => widget.urun;

  /// Seçilebilecek en yüksek adet: stok ile üst sınırın küçüğü.
  int get _adetTavani =>
      _urun.stok < _enFazlaAdet ? _urun.stok : _enFazlaAdet;

  Future<void> _sepeteEkle() async {
    setState(() => _ekleniyor = true);

    String? hata;

    try {
      await _sepetServisi.ekle(urunId: _urun.id, adet: _adet);
    } catch (yakalanan) {
      hata = hataMesaji(yakalanan);
    }

    if (!mounted) return;

    setState(() => _ekleniyor = false);

    final mesajci = ScaffoldMessenger.of(context);
    mesajci.hideCurrentSnackBar();

    mesajci.showSnackBar(
      SnackBar(
        content: Text(hata ?? '$_adet adet sepete eklendi.'),
        backgroundColor:
            hata == null ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        actions: [
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
            tag: 'urun-gorsel-${_urun.id}',
            child: AspectRatio(
              aspectRatio: 1,
              child: _DetayGorseli(adres: _urun.gorselUrl),
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
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.primary,
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
                  _AdetSecici(
                    adet: _adet,
                    tavan: _adetTavani,
                    onDegisti: (yeni) => setState(() => _adet = yeni),
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  // Stok yoksa buton pasif. Nedeni hemen altında yazıyor ki
                  // kullanıcı butonun neden çalışmadığını anlasın.
                  onPressed:
                      (!_urun.stoktaVar || _ekleniyor) ? null : _sepeteEkle,
                  icon: _ekleniyor
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

class _DetayGorseli extends StatelessWidget {
  final String? adres;

  const _DetayGorseli({required this.adres});

  @override
  Widget build(BuildContext context) {
    final tamAdres = ApiSabitleri.tamGorselAdresi(adres);

    Widget yerTutucu() => Container(
          color: Colors.grey.shade200,
          child: Icon(
            Icons.image_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
        );

    if (tamAdres.isEmpty) return yerTutucu();

    return CachedNetworkImage(
      imageUrl: tamAdres,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => yerTutucu(),
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

/// Eksi/artı düğmeleriyle adet seçimi. Sınırlar dışına çıkan düğme pasifleşir.
class _AdetSecici extends StatelessWidget {
  final int adet;
  final int tavan;
  final ValueChanged<int> onDegisti;

  const _AdetSecici({
    required this.adet,
    required this.tavan,
    required this.onDegisti,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Adet', style: TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: adet > 1 ? () => onDegisti(adet - 1) : null,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$adet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: adet < tavan ? () => onDegisti(adet + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
