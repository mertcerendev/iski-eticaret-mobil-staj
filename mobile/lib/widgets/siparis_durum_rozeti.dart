import 'package:flutter/material.dart';

import '../models/siparis.dart';

/// Sipariş durumunu renkli bir rozet olarak gösterir.
///
/// Renk eşlemesi modelde değil burada duruyor: `SiparisDurumu` yalnızca
/// sunucunun anahtarını ve Türkçe etiketi biliyor, Flutter'a bağımlı değil.
/// Renk bir görünüm kararı olduğu için widget katmanında kalıyor.
///
/// Hem sipariş listesinde hem detay ekranında kullanıldığı için ortak dosyada.
class SiparisDurumRozeti extends StatelessWidget {
  final SiparisDurumu durum;

  /// Detay ekranında daha büyük gösteriliyor.
  final bool buyuk;

  const SiparisDurumRozeti({
    super.key,
    required this.durum,
    this.buyuk = false,
  });

  /// Durumun akıştaki yerine göre renk. Bekleyen gri, yolda olan mavi tonları,
  /// biten yeşil, iptal kırmızı — kullanıcı rengi okumadan da anlıyor.
  Color get _renk {
    switch (durum) {
      case SiparisDurumu.bekliyor:
        return Colors.grey.shade600;
      case SiparisDurumu.odendi:
        return Colors.blue.shade700;
      case SiparisDurumu.hazirlaniyor:
        return Colors.orange.shade800;
      case SiparisDurumu.kargoda:
        return Colors.indigo.shade600;
      case SiparisDurumu.teslimEdildi:
        return Colors.green.shade700;
      case SiparisDurumu.iptalEdildi:
        return Colors.red.shade700;
    }
  }

  IconData get _simge {
    switch (durum) {
      case SiparisDurumu.bekliyor:
        return Icons.schedule;
      case SiparisDurumu.odendi:
        return Icons.check_circle_outline;
      case SiparisDurumu.hazirlaniyor:
        return Icons.inventory_2_outlined;
      case SiparisDurumu.kargoda:
        return Icons.local_shipping_outlined;
      case SiparisDurumu.teslimEdildi:
        return Icons.done_all;
      case SiparisDurumu.iptalEdildi:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: buyuk ? 12 : 8,
        vertical: buyuk ? 6 : 4,
      ),
      decoration: BoxDecoration(
        // Zemin, yazı renginin çok açık tonu: rozet okunur kalıyor ama
        // dolu renk kadar dikkat çekmiyor.
        color: _renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_simge, size: buyuk ? 16 : 13, color: _renk),
          const SizedBox(width: 5),
          Text(
            durum.etiket,
            style: TextStyle(
              color: _renk,
              fontSize: buyuk ? 13 : 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
