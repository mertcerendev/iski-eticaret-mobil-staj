import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../models/urun.dart';
import 'favori_dugmesi.dart';

/// Izgarada tek bir ürünü gösteren kart.
///
/// Gün 2'de liste biçiminde yazılmıştı; ürünler API'den görselleriyle
/// gelmeye başlayınca ızgaraya uygun dikey düzene çevrildi.
class UrunKarti extends StatelessWidget {
  final Urun urun;
  final VoidCallback? onTap;

  const UrunKarti({super.key, required this.urun, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Aynı etiket detay ekranındaki görselde de var; iki ekran
                // arasında büyüyerek geçen animasyonu Hero kuruyor.
                Hero(
                  tag: 'urun-gorsel-${urun.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _Gorsel(adres: urun.gorselUrl),
                  ),
                ),

                // Stok bilgisi görselin üzerinde rozet olarak durur;
                // kart yüksekliğini artırmadan görünür olur.
                Positioned(
                  top: 8,
                  left: 8,
                  child: _StokRozeti(urun: urun),
                ),

                Positioned(
                  top: 2,
                  right: 2,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: FavoriDugmesi(urun: urun),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urun.ad,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Bazı uçlar ürünü kategorisiz döndürebilir; o durumda
                  // boş satır bırakmak yerine hiç çizilmez.
                  if (urun.kategori != null)
                    Text(
                      urun.kategori!.ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 8),

                  Text(
                    urun.fiyatMetni,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ürün görselini gösterir; adres yoksa ya da yüklenemezse yer tutucu çizer.
class _Gorsel extends StatelessWidget {
  final String? adres;

  const _Gorsel({required this.adres});

  @override
  Widget build(BuildContext context) {
    final tamAdres = ApiSabitleri.tamGorselAdresi(adres);

    if (tamAdres.isEmpty) return const _YerTutucu();

    // cached_network_image bir kez indirdiği görseli saklar; listede
    // yukarı aşağı kaydırıldığında aynı görsel tekrar indirilmez.
    return CachedNetworkImage(
      imageUrl: tamAdres,
      fit: BoxFit.cover,
      placeholder: (_, _) => const _YerTutucu(yukleniyor: true),
      errorWidget: (_, _, _) => const _YerTutucu(),
    );
  }
}

class _YerTutucu extends StatelessWidget {
  final bool yukleniyor;

  const _YerTutucu({this.yukleniyor = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: yukleniyor
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
      ),
    );
  }
}

class _StokRozeti extends StatelessWidget {
  final Urun urun;

  const _StokRozeti({required this.urun});

  @override
  Widget build(BuildContext context) {
    // Renk kararı stok durumuna bağlı: tükendi kırmızı, azaldı turuncu.
    // Yeterli stokta rozet hiç gösterilmez — ekran gereksiz kalabalıklaşmasın.
    if (urun.stoktaVar && !urun.sonUrunler) return const SizedBox.shrink();

    final renk = urun.stoktaVar ? Colors.orange.shade700 : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        urun.stokMetni,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
