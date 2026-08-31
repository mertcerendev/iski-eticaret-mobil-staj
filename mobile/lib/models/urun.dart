import 'kategori.dart';

/// Sunucudaki `Product` kaydının karşılığı.
class Urun {
  final int id;
  final String ad;
  final String aciklama;
  final double fiyat;
  final int stok;
  final String? gorselUrl;
  final bool aktif;
  final int kategoriId;

  /// Sunucu ürünü `include` ile kategorisiyle birlikte döndürür.
  /// Bazı uçlarda (örneğin sepet) gelmediği için boş olabilir.
  final Kategori? kategori;

  const Urun({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.fiyat,
    required this.stok,
    required this.kategoriId,
    this.gorselUrl,
    this.aktif = true,
    this.kategori,
  });

  // ── Hesaplanan özellikler ───────────────────────────────────────
  // Bu kararlar modelin içinde durur. Ekran "stok > 0 mu" diye
  // sorgulamaz, hazır cevabı okur; kural değişirse tek yer değişir.

  bool get stoktaVar => stok > 0;

  bool get sonUrunler => stok > 0 && stok < 5;

  String get stokMetni {
    if (!stoktaVar) return 'Tükendi';
    if (sonUrunler) return 'Son $stok adet';
    return 'Stokta';
  }

  String get fiyatMetni => '${fiyat.toStringAsFixed(2)} TL';

  /// Sunucu para alanlarını (`price`, `subtotal`, `totalAmount`) `Decimal`
  /// tipinden metin olarak gönderir ("1499.9"). Kuruş hassasiyeti sunucuda
  /// korunduğu için burada gösterim amaçlı `double`'a çevrilir.
  ///
  /// Sepet modeli de aynı çeviriyi kullandığı için dışa açık.
  static double sayiyaCevir(Object? deger) {
    if (deger == null) return 0;
    if (deger is num) return deger.toDouble();
    return double.tryParse(deger.toString()) ?? 0;
  }

  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      id: json['id'] as int,
      ad: json['name'] as String,
      aciklama: (json['description'] as String?) ?? '',
      fiyat: sayiyaCevir(json['price']),
      stok: (json['stock'] as int?) ?? 0,
      gorselUrl: json['imageUrl'] as String?,
      aktif: (json['isActive'] as bool?) ?? true,
      kategoriId: (json['categoryId'] as int?) ?? 0,
      kategori: json['category'] == null
          ? null
          : Kategori.fromJson(json['category'] as Map<String, dynamic>),
    );
  }
}
