import 'package:flutter/material.dart';

/// Ekranın altında kısa uyarı şeridi (SnackBar) gösterir.
///
/// Altı ayrı yerde aynı üçlü tekrar ediyordu: öncekini gizle, rengi duruma
/// göre seç, göster. Tek yere alındı — böylece hata kırmızısı ile başarı
/// yeşili uygulamanın her yerinde aynı.
///
/// **Neden fonksiyon değil de sınıf?** Asenkron çağrıdan SONRA bildirim
/// göstermek gerekiyor. O sırada ekran kapanmış olabileceği için `context`
/// artık kullanılamaz. Bu sınıf kurulurken ihtiyacı olan iki şeyi
/// (mesajcı ve hata rengi) önden alıyor; böylece `await`ten önce oluşturulup
/// sonra güvenle çağrılabiliyor:
///
/// ```dart
/// final bildir = Bildirim(context);      // await'ten ÖNCE
/// final hata = await saglayici.birSey();
/// if (hata != null) bildir.hata(hata);   // await'ten SONRA, güvenli
/// ```
class Bildirim {
  final ScaffoldMessengerState _mesajci;
  final Color _hataRengi;

  Bildirim(BuildContext context)
      : _mesajci = ScaffoldMessenger.of(context),
        _hataRengi = Theme.of(context).colorScheme.error;

  void hata(String mesaj) => _goster(mesaj, _hataRengi);

  void basari(String mesaj) => _goster(mesaj, Colors.green.shade700);

  /// Hata varsa kırmızı, yoksa yeşil gösterir. Sonucu "hata mesajı ya da
  /// null" biçiminde dönen sağlayıcı metotlarıyla doğrudan kullanılır.
  void sonuc(String? hataMesaji, String basariMesaji) {
    hataMesaji == null ? basari(basariMesaji) : hata(hataMesaji);
  }

  void _goster(String mesaj, Color renk) {
    // Önceki şerit hâlâ ekrandaysa kaldırılır; yoksa yenisi kuyruğa girip
    // gecikmeli görünür.
    _mesajci.hideCurrentSnackBar();

    _mesajci.showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk),
    );
  }
}
