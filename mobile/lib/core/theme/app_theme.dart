import 'package:flutter/material.dart';

/// Uygulamanın görsel dili.
///
/// Renk ve kenarlık gibi kararlar tek yerde toplanır; ekranlar kendi
/// içinde renk tanımlamaz. Tema değişince tüm uygulama birlikte değişir.
class UygulamaTemasi {
  UygulamaTemasi._();

  static const Color _cekirdekRenk = Color(0xFF1B4D8F);

  static ThemeData get acik {
    final renkSemasi = ColorScheme.fromSeed(seedColor: _cekirdekRenk);

    return ThemeData(
      colorScheme: renkSemasi,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),

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
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
