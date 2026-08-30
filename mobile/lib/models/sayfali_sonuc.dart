/// Sunucunun sayfalı uçlardan döndürdüğü zarfın karşılığı.
///
/// Ürün listesi `{ items, total, page, limit, totalPages }` biçiminde gelir.
/// Aynı yapı ileride sipariş listesinde de kullanılacağı için tür
/// belirtilmeden (generic) yazılmıştır: `SayfaliSonuc<Urun>`.
class SayfaliSonuc<T> {
  final List<T> kayitlar;
  final int toplam;
  final int sayfa;
  final int limit;
  final int toplamSayfa;

  const SayfaliSonuc({
    required this.kayitlar,
    required this.toplam,
    required this.sayfa,
    required this.limit,
    required this.toplamSayfa,
  });

  /// Sonsuz kaydırmada "daha var mı" kararını verir.
  bool get sonSayfaMi => sayfa >= toplamSayfa;

  /// [cozumleyici], her bir kaydı nesneye çeviren fonksiyondur. Zarfı çözmek
  /// her tür için aynı, kaydı çözmek türe özeldir; o yüzden dışarıdan alınır.
  factory SayfaliSonuc.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) cozumleyici,
  ) {
    final ham = (json['items'] as List<dynamic>?) ?? const [];

    return SayfaliSonuc(
      kayitlar: ham
          .map((kayit) => cozumleyici(kayit as Map<String, dynamic>))
          .toList(),
      toplam: (json['total'] as int?) ?? 0,
      sayfa: (json['page'] as int?) ?? 1,
      limit: (json['limit'] as int?) ?? 0,
      toplamSayfa: (json['totalPages'] as int?) ?? 0,
    );
  }
}
