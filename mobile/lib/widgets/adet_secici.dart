import 'package:flutter/material.dart';

/// Eksi/artı düğmeleriyle adet seçen kutu.
///
/// Gün 10'da ürün detay ekranının içinde özel bir sınıftı. Gün 11'de sepet
/// satırında da aynısı gerektiği için buraya taşındı: iki yerde aynı görünüm
/// ve aynı sınır davranışı olsun, kural değişirse tek dosya değişsin.
class AdetSecici extends StatelessWidget {
  final int adet;

  /// Seçilebilecek en yüksek adet; artı düğmesi bu değerde pasifleşir.
  final int tavan;

  final ValueChanged<int> onDegisti;

  /// Sunucuya istek gitmişken kapatılır. Kapatılmazsa kullanıcı artıya üst
  /// üste basıp aynı satır için birbirini ezen istekler gönderebilir.
  final bool etkin;

  const AdetSecici({
    super.key,
    required this.adet,
    required this.tavan,
    required this.onDegisti,
    this.etkin = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            // En az 1 adet kalır; sıfıra indirme yerine satır silinir.
            onPressed: etkin && adet > 1 ? () => onDegisti(adet - 1) : null,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$adet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: etkin && adet < tavan ? () => onDegisti(adet + 1) : null,
          ),
        ],
      ),
    );
  }
}
