import 'package:flutter/services.dart';

/// Kart alanlarına yazılırken araya ayraç koyan biçimlendiriciler.
///
/// Ödeme ekranının içindeydiler; öykünücüde tek bir haneyi düzeltirken
/// numaranın karıştığı görülünce buraya alındılar. Ayrı dosyada olmalarının
/// sebebi sınanabilmeleri: aşağıdaki imleç hesabı elle denemesi zor,
/// birim testiyle sabitlemesi kolay bir davranış.

/// Ayraç ekleyen biçimlendiricilerin ortak işi.
///
/// İşin zor kısmı metin değil **imleç**. Araya karakter girdiği için imlecin
/// yeni konumu sondan sayarak bulunamaz. Çözüm, imlecin kaçıncı rakamın
/// arkasında durduğunu ölçüp yeni metinde aynı rakam sayısını geçtikten
/// sonraki konumu bulmaktır.
///
/// İmleç körü körüne metnin sonuna atılsaydı, alanın ortasındaki bir haneyi
/// düzeltmek isteyen kullanıcının yazdığı rakam sona eklenir ve numara
/// karışırdı.
TextEditingValue ayracliBicimle(
  TextEditingValue yeni,
  String ayraclar,
  String Function(String rakamlar) uret,
) {
  bool ayracMi(String karakter) => ayraclar.contains(karakter);

  final imlec = yeni.selection.baseOffset.clamp(0, yeni.text.length);

  final imlectenOnceRakam = yeni.text
      .substring(0, imlec)
      .split('')
      .where((karakter) => !ayracMi(karakter))
      .length;

  final metin = uret(
    yeni.text.split('').where((karakter) => !ayracMi(karakter)).join(),
  );

  var konum = 0;
  var sayac = 0;

  while (konum < metin.length && sayac < imlectenOnceRakam) {
    if (!ayracMi(metin[konum])) sayac++;
    konum++;
  }

  return TextEditingValue(
    text: metin,
    selection: TextSelection.collapsed(offset: konum),
  );
}

/// Kart numarasını 4'erli gruplara ayırır: 4242424242424242 → 4242 4242 ...
///
/// Yalnızca görünümü değiştirir; doğrulayıcı boşlukları zaten atıyor.
class KartNumarasiBicimi extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue eski,
    TextEditingValue yeni,
  ) {
    return ayracliBicimle(yeni, ' ', (rakamlar) {
      final tampon = StringBuffer();

      for (var i = 0; i < rakamlar.length; i++) {
        if (i > 0 && i % 4 == 0) tampon.write(' ');
        tampon.write(rakamlar[i]);
      }

      return tampon.toString();
    });
  }
}

/// İki hane girilince araya "/" koyar: 1228 → 12/28
class SonKullanmaBicimi extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue eski,
    TextEditingValue yeni,
  ) {
    return ayracliBicimle(yeni, '/', (rakamlar) {
      return rakamlar.length <= 2
          ? rakamlar
          : '${rakamlar.substring(0, 2)}/${rakamlar.substring(2)}';
    });
  }
}
