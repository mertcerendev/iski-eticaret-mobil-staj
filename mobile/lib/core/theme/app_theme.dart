import 'package:flutter/material.dart';

/// Uygulamanın görsel dili.
///
/// Renk ve kenarlık gibi kararlar tek yerde toplanır; ekranlar kendi
/// içinde renk tanımlamaz. Tema değişince tüm uygulama birlikte değişir.
class UygulamaTemasi {
  UygulamaTemasi._();

  static const Color _cekirdekRenk = Color(0xFF1B4D8F);

  /// Fiyat, indirim ve dikkat çekmesi gereken rozetlerin rengi.
  ///
  /// Tek renkli bir arayüzde fiyat da başlık da aynı ağırlıkta okunuyordu.
  /// E-ticaret uygulamalarında fiyat en hızlı bulunması gereken bilgi olduğu
  /// için ikinci bir renk ayrıldı. Kurumsal mavi kimliği taşımaya devam
  /// ediyor; turuncu yalnızca vurgu için kullanılıyor.
  static const Color vurgu = Color(0xFFE8590C);

  /// Kart ve bölüm zeminlerinde kullanılan kırık beyaz.
  static const Color yuzey = Color(0xFFFFFFFF);

  /// Ekran zemini. Kartlar beyaz olduğu için zemin hafif gri: sınırları
  /// çizgiyle değil renk farkıyla belli ediyor.
  static const Color zemin = Color(0xFFF2F4F7);

  static ThemeData get acik {
    final renkSemasi = ColorScheme.fromSeed(seedColor: _cekirdekRenk);

    return ThemeData(
      colorScheme: renkSemasi,
      useMaterial3: true,
      scaffoldBackgroundColor: zemin,

      appBarTheme: AppBarTheme(
        backgroundColor: renkSemasi.primary,
        foregroundColor: renkSemasi.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Form alanlarının ortak görünümü. Her TextFormField'da ayrı ayrı
      // kenarlık tanımlamamak için burada bir kez belirlenir.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: renkSemasi.primary, width: 2),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        // Gölge yerine ince kenarlık: düz zeminde daha temiz duruyor ve
        // yan yana kartlarda gölgeler birbirine karışmıyor.
        color: yuzey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),

      // Bölüm başlıkları ve gövde metni için tutarlı ölçek.
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14, height: 1.4),
        bodySmall: TextStyle(fontSize: 12),
      ),

      chipTheme: ChipThemeData(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
