import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';

/// Ürün görselini gösterir; adres yoksa ya da yüklenemezse yer tutucu çizer.
///
/// Aynı iş önce ürün kartında, sonra detay ekranında, sonra sepet satırında
/// ayrı ayrı yazılmıştı — üç neredeyse aynı sınıf. Tek yere alındı; aralarındaki
/// tek fark yer tutucu simgesinin boyutuydu, o da parametre oldu.
class UrunGorseli extends StatelessWidget {
  final String? adres;

  /// Yer tutucu simgesinin boyutu. Sepet satırı küçük, kart orta,
  /// detay ekranı büyük gösteriyor.
  final double simgeBoyutu;

  const UrunGorseli({super.key, required this.adres, this.simgeBoyutu = 32});

  @override
  Widget build(BuildContext context) {
    final tamAdres = ApiSabitleri.tamGorselAdresi(adres);

    if (tamAdres.isEmpty) return _yerTutucu();

    // cached_network_image bir kez indirdiği görseli saklar; listede yukarı
    // aşağı kaydırıldığında aynı görsel tekrar indirilmez.
    return CachedNetworkImage(
      imageUrl: tamAdres,
      fit: BoxFit.cover,
      placeholder: (_, _) => _yerTutucu(yukleniyor: true),
      errorWidget: (_, _, _) => _yerTutucu(),
    );
  }

  Widget _yerTutucu({bool yukleniyor = false}) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: yukleniyor
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.image_outlined,
                color: Colors.grey.shade400,
                size: simgeBoyutu,
              ),
      ),
    );
  }
}
