import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/urun.dart';
import 'favori_dugmesi.dart';
import 'urun_gorseli.dart';

/// Izgarada tek bir ürünü gösteren kart.
///
/// Gün 2'de liste biçiminde yazılmıştı; ürünler API'den görselleriyle
/// gelmeye başlayınca ızgaraya uygun dikey düzene çevrildi. Gün 20'den sonra
/// görsel dil elden geçirildi: fiyat vurgu rengiyle ve büyük punto ile
/// yazılıyor, ürün adı ikincil ağırlığa indirildi. E-ticarette gözün ilk
/// aradığı bilgi fiyattır.
class UrunKarti extends StatelessWidget {
  final Urun urun;
  final VoidCallback? onTap;

  /// Hero etiketinin önüne eklenen sekme adı.
  ///
  /// Gün 11'de alt gezinme gelince ana sayfa ile favoriler `IndexedStack`
  /// sayesinde aynı anda ağaçta durmaya başladı. Aynı ürün ikisinde birden
  /// varsa iki Hero aynı etiketi taşıyor ve Flutter "aynı etiketli birden
  /// çok Hero" hatası veriyor. Sekme adı öne eklenerek etiketler ayrılır.
  final String heroOneki;

  /// Yatay şeritlerde kart daha dar çiziliyor; ızgarada genişliği kısıtlanmaz.
  final double? genislik;

  // Kart yüksekliği bu ölçülerden hesaplanıyor; ana ekrandaki ızgara oranı
  // ve şerit yüksekliği bunlara göre ayarlandı.
  static const double _adPunto = 13.5;
  static const double _adSatirAraligi = 1.25;

  /// İki satırlık ad kutusunun yüksekliği.
  static const double _adYuksekligi = _adPunto * _adSatirAraligi * 2;

  /// Görselin altındaki metin bölümünün gerektirdiği yükseklik.
  ///
  /// Değer hesapla değil **ölçerek** bulundu: taşma hatasının bildirdiği
  /// eksik piksel kadar artırılıp test yeşile dönene kadar denendi. Punto ve
  /// satır aralığı temadan da miras alındığı için kâğıt üstündeki toplam
  /// gerçeği tutmuyordu.
  static const double metinYuksekligi = 119;

  const UrunKarti({
    super.key,
    required this.urun,
    required this.heroOneki,
    this.onTap,
    this.genislik,
  });

  @override
  Widget build(BuildContext context) {
    final kart = Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Görsel zemini beyaz: ürün fotoğraflarının çoğu beyaz
                // zeminli olduğu için kartla birleşiyor, kırpılmış durmuyor.
                Container(
                  color: Colors.white,
                  child: Hero(
                    tag: '$heroOneki-urun-gorsel-${urun.id}',
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: UrunGorseli(adres: urun.gorselUrl),
                    ),
                  ),
                ),

                Positioned(top: 8, left: 8, child: _StokRozeti(urun: urun)),

                Positioned(
                  top: 4,
                  right: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
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

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ad her zaman iki satırlık yer kaplıyor: tek satırlık
                    // adlarda ikinci satır boş kalıyor ama bütün kartlarda
                    // kategori ve fiyat aynı hizada duruyor. Esnek
                    // bırakıldığında kart alçalınca harflerin alt kuyrukları
                    // kırpılıyordu.
                    SizedBox(
                      height: _adYuksekligi,
                      child: Text(
                        urun.ad,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: _adPunto,
                          fontWeight: FontWeight.w500,
                          height: _adSatirAraligi,
                        ),
                      ),
                    ),

                    // Esnek boşluk: ürün adı bir satır da olsa iki satır da
                    // olsa fiyat kartın altına yaslanıyor, ızgarada bütün
                    // fiyatlar aynı hizada duruyor.
                    const Spacer(),

                    if (urun.kategori != null)
                      Text(
                        urun.kategori!.ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),

                    Text(
                      urun.fiyatMetni,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: UygulamaTemasi.vurgu,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return genislik == null ? kart : SizedBox(width: genislik, child: kart);
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

    final renk = urun.stoktaVar ? Colors.orange.shade800 : Colors.red.shade700;

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
