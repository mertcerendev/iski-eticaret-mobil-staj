/// API adreslerinin tek toplandığı yer.
///
/// Adres bir yerde değişirse yalnızca bu dosya güncellenir; ekranlar ve
/// servisler metin olarak adres taşımaz.
class ApiSabitleri {
  ApiSabitleri._();

  /// Android emulator, geliştirme bilgisayarının localhost'una `10.0.2.2`
  /// üzerinden ulaşır. Emulator'ün kendi `localhost`'u kendisidir.
  static const String sunucu = 'http://10.0.2.2:3000';

  static const String temelAdres = '$sunucu/api';

  // Kimlik doğrulama
  static const String kayit = '/auth/register';
  static const String giris = '/auth/login';
  static const String profil = '/auth/me';
  static const String parolaDegistir = '/auth/me/password';

  // Katalog
  static const String kategoriler = '/categories';
  static const String urunler = '/products';

  // Kullanıcıya özel
  static const String sepet = '/cart';
  static const String favoriler = '/favorites';
  static const String siparisler = '/orders';

  // Yönetici
  static const String gorselYukle = '/upload';

  /// Sunucu `/uploads/urun-123.png` biçiminde göreli adres döndürür.
  /// Görsel bileşenleri tam adres beklediği için başına sunucu eklenir.
  static String tamGorselAdresi(String? goreliAdres) {
    if (goreliAdres == null || goreliAdres.isEmpty) return '';
    if (goreliAdres.startsWith('http')) return goreliAdres;
    return '$sunucu$goreliAdres';
  }
}
