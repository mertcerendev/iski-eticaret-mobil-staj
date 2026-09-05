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

  // ── Sipariş ve ödeme alanları ──────────────────────────────────────
  // Buradaki kurallar da sunucudaki `order.service.js` ile birebir aynı.

  static String? adres(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Teslimat adresi zorunludur.';
    if (metin.length < 10) return 'Adres en az 10 karakter olmalıdır.';
    if (metin.length > 500) return 'Adres en fazla 500 karakter olabilir.';

    return null;
  }

  /// Kart numarasının son hanesi, önceki hanelerden üretilen bir kontrol
  /// hanesidir (Luhn). Bu denetim sahteciliği değil **yazım hatasını**
  /// yakalar: tek hane yanlış girildiğinde ya da iki hane yer değiştirdiğinde
  /// tutmaz. Kullanıcı hatayı sunucuya gitmeden görür.
  static bool luhnGecerli(String rakamlar) {
    var toplam = 0;

    for (var i = 0; i < rakamlar.length; i++) {
      var hane = int.parse(rakamlar[rakamlar.length - 1 - i]);

      if (i.isOdd) {
        hane *= 2;
        if (hane > 9) hane -= 9;
      }

      toplam += hane;
    }

    return toplam % 10 == 0;
  }

  static String? kartNumarasi(String? deger) {
    // Ekranda 4'erli gruplar hâlinde gösterildiği için boşluklar atılır.
    final rakamlar = (deger ?? '').replaceAll(RegExp(r'[\s-]'), '');

    if (rakamlar.isEmpty) return 'Kart numarası zorunludur.';
    if (!RegExp(r'^\d{16}$').hasMatch(rakamlar)) {
      return 'Kart numarası 16 haneli olmalıdır.';
    }
    if (!luhnGecerli(rakamlar)) return 'Kart numarası geçersiz.';

    return null;
  }

  static String? sonKullanma(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Son kullanma tarihi zorunludur.';

    final eslesme = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(metin);

    if (eslesme == null) return 'AA/YY biçiminde giriniz.';

    final ay = int.parse(eslesme.group(1)!);
    final yil = 2000 + int.parse(eslesme.group(2)!);

    // Kart, son kullanma ayının son gününe kadar geçerlidir; bu yüzden
    // bir sonraki ayın ilk günüyle karşılaştırılır.
    if (!DateTime(yil, ay + 1, 1).isAfter(DateTime.now())) {
      return 'Kartın son kullanma tarihi geçmiş.';
    }

    return null;
  }

  static String? cvv(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Güvenlik kodu zorunludur.';
    if (!RegExp(r'^\d{3}$').hasMatch(metin)) {
      return 'Güvenlik kodu 3 haneli olmalıdır.';
    }

    return null;
  }

  // ── Yönetici ürün formu ────────────────────────────────────────────
  // Kurallar `product.service.js` ile birebir aynı: ad 200, açıklama 2000
  // karakter; fiyat en fazla iki ondalık basamaklı; stok negatif olamaz.

  static String? urunAdi(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Ürün adı zorunludur.';
    if (metin.length > 200) return 'Ürün adı en fazla 200 karakter olabilir.';

    return null;
  }

  static String? urunAciklamasi(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Açıklama zorunludur.';
    if (metin.length > 2000) {
      return 'Açıklama en fazla 2000 karakter olabilir.';
    }

    return null;
  }

  /// Sunucu fiyatı metin olarak alıyor ve `^\d+(\.\d{1,2})?$` deseniyle
  /// denetliyor. Aynı desen burada da uygulanıyor; virgül kabul edilmiyor
  /// çünkü sunucuya nokta ile gitmesi gerekiyor.
  static String? fiyat(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Fiyat zorunludur.';

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(metin)) {
      return 'Fiyat 0 veya daha büyük, en fazla iki ondalıklı olmalıdır.';
    }

    return null;
  }

  static String? stok(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Stok zorunludur.';

    final sayi = int.tryParse(metin);

    if (sayi == null || sayi < 0) {
      return 'Stok 0 veya daha büyük bir tam sayı olmalıdır.';
    }

    return null;
  }

  static String? kartSahibi(String? deger) {
    final metin = deger?.trim() ?? '';

    if (metin.isEmpty) return 'Kart üzerindeki ad zorunludur.';
    if (metin.length < 3) return 'Ad en az 3 karakter olmalıdır.';
    if (metin.length > 100) return 'Ad en fazla 100 karakter olabilir.';

    return null;
  }
}
