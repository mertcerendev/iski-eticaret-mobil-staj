import 'urun.dart';

/// Sepetteki tek satır: bir ürün ve o üründen kaç adet alındığı.
///
/// Satırın kendi kimliği (`cartItem.id`) sunucudan geliyor ama burada
/// tutulmuyor; sepet uçlarının hepsi satırı **ürün kimliğiyle** adresliyor
/// (`PUT /cart/12`, `DELETE /cart/12`). Kullanılmayacak alan taşınmıyor.
class SepetSatiri {
  final int urunId;
  final int adet;
  final Urun urun;

  /// Bu satırın tutarı: birim fiyat × adet. Sunucuda hesaplanır.
  final double araToplam;

  /// Ürün sepete girdikten sonra pasife alınmış ya da stoğu satırdaki
  /// adedin altına düşmüş olabilir. Sunucu böyle satırları genel toplama
  /// katmaz, silmez de — karar kullanıcıya bırakılır. Bu bayrak olmasaydı
  /// satırların toplamı ile ekranda yazan toplam tutmazdı.
  final bool satinAlinabilir;

  const SepetSatiri({
    required this.urunId,
    required this.adet,
    required this.urun,
    required this.araToplam,
    required this.satinAlinabilir,
  });

  String get araToplamMetni => '${araToplam.toStringAsFixed(2)} TL';

  factory SepetSatiri.fromJson(Map<String, dynamic> json) {
    return SepetSatiri(
      urunId: json['productId'] as int,
      adet: json['quantity'] as int,
      urun: Urun.fromJson(json['product'] as Map<String, dynamic>),
      araToplam: Urun.sayiyaCevir(json['subtotal']),
      satinAlinabilir: (json['satinAlinabilir'] as bool?) ?? true,
    );
  }
}

/// Sepetin tamamı.
///
/// Sepeti değiştiren her uç (ekleme, adet güncelleme, çıkarma) yanıt olarak
/// sepetin son hâlini döndürür. Bu yüzden mobil taraf toplamı kendi
/// hesaplamaz; sunucudan geleni gösterir. Para hesabı tek yerde kalır.
class Sepet {
  final List<SepetSatiri> satirlar;
  final double toplamTutar;

  /// Satır sayısı değil, adetlerin toplamı. Alt gezinmedeki rozet bunu yazar.
  final int toplamAdet;

  const Sepet({
    required this.satirlar,
    required this.toplamTutar,
    required this.toplamAdet,
  });

  /// Sunucudan henüz yanıt gelmeden önceki başlangıç değeri.
  const Sepet.bos()
      : satirlar = const [],
        toplamTutar = 0,
        toplamAdet = 0;

  bool get bosMu => satirlar.isEmpty;

  String get toplamMetni => '${toplamTutar.toStringAsFixed(2)} TL';

  factory Sepet.fromJson(Map<String, dynamic> json) {
    return Sepet(
      satirlar: (json['items'] as List)
          .map((satir) => SepetSatiri.fromJson(satir as Map<String, dynamic>))
          .toList(),
      toplamTutar: Urun.sayiyaCevir(json['totalAmount']),
      toplamAdet: (json['totalQuantity'] as int?) ?? 0,
    );
  }
}
