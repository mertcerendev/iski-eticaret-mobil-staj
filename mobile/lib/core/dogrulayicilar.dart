/// Form alanlarının ortak doğrulama kuralları.
///
/// Kurallar sunucudakilerle aynı. İstemcide de bulunmasının sebebi hız:
/// kullanıcı hatalı veri girdiğinde sunucuya gidip dönmeyi beklemeden
/// uyarıyı görür. Asıl güvenlik yine sunucudadır — istemci doğrulaması
/// atlatılabilir.
///
/// Giriş ve kayıt ekranı aynı kuralları kullandığı için tek dosyada
/// toplanmıştır.
class Dogrulayicilar {
  Dogrulayicilar._();

  static final RegExp _epostaDeseni = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? eposta(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'E-posta zorunludur.';
    if (!_epostaDeseni.hasMatch(metin)) {
      return 'Geçerli bir e-posta adresi giriniz.';
    }

    return null;
  }

  static String? parola(String? deger) {
    final metin = deger ?? '';

    if (metin.isEmpty) return 'Parola zorunludur.';
    if (metin.length < 8) return 'Parola en az 8 karakter olmalıdır.';

    return null;
  }

  static String? adSoyad(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Ad soyad zorunludur.';
    if (metin.length < 3) return 'Ad soyad en az 3 karakter olmalıdır.';
    if (metin.length > 100) return 'Ad soyad en fazla 100 karakter olabilir.';

    return null;
  }

  /// Parola tekrarı yalnızca istemcide vardır; sunucuya tek parola gider.
  /// Amacı kullanıcının yazım hatasını kayıt olmadan önce yakalamak.
  static String? parolaTekrari(String? deger, String parola) {
    final metin = deger ?? '';

    if (metin.isEmpty) return 'Parolayı tekrar giriniz.';
    if (metin != parola) return 'Parolalar eşleşmiyor.';

    return null;
  }
}
