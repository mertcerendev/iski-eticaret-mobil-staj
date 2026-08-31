/// Siparişin sunucudaki durum makinesindeki yeri.
///
/// Anahtarlar sunucudaki `OrderStatus` enum'u ile birebir aynı; etiketler
/// yalnızca ekranda gösterilmek içindir. Gün 9'daki `Siralama` enum'u ile
/// aynı düşünce: sunucunun tanıdığı değer tek yerde tutulur.
enum SiparisDurumu {
  bekliyor('PENDING', 'Ödeme bekliyor'),
  odendi('PAID', 'Ödendi'),
  hazirlaniyor('PREPARING', 'Hazırlanıyor'),
  kargoda('SHIPPED', 'Kargoya verildi'),
  teslimEdildi('DELIVERED', 'Teslim edildi'),
  iptalEdildi('CANCELLED', 'İptal edildi');

  final String anahtar;
  final String etiket;

  const SiparisDurumu(this.anahtar, this.etiket);

  /// Sunucuya ileride yeni bir durum eklenirse uygulama çökmesin diye
  /// tanınmayan değer için varsayılan döndürülür.
  static SiparisDurumu cozumle(String? deger) {
    return SiparisDurumu.values.firstWhere(
      (durum) => durum.anahtar == deger,
      orElse: () => SiparisDurumu.bekliyor,
    );
  }
}

/// Siparişteki tek kalem.
///
/// Fiyat, ürünün bugünkü fiyatı değil **sipariş anındaki** fiyatıdır; sunucu
/// bunu `unitPrice` alanına dondurur. Ürünün fiyatı sonradan değişse bile
/// geçmiş sipariş aynı tutarı göstermeye devam eder.
class SiparisKalemi {
  final int urunId;
  final String urunAd;
  final String? gorselUrl;
  final int adet;
  final double birimFiyat;

  const SiparisKalemi({
    required this.urunId,
    required this.urunAd,
    required this.adet,
    required this.birimFiyat,
    this.gorselUrl,
  });

  double get araToplam => birimFiyat * adet;

  String get birimFiyatMetni => '${birimFiyat.toStringAsFixed(2)} TL';
  String get araToplamMetni => '${araToplam.toStringAsFixed(2)} TL';

  factory SiparisKalemi.fromJson(Map<String, dynamic> json) {
    final urun = json['product'] as Map<String, dynamic>?;

    return SiparisKalemi(
      urunId: json['productId'] as int,
      // Ürün silinmiş olsa bile sipariş görüntülenebilmeli.
      urunAd: (urun?['name'] as String?) ?? 'Ürün',
      gorselUrl: urun?['imageUrl'] as String?,
      adet: json['quantity'] as int,
      birimFiyat: _sayiyaCevir(json['unitPrice']),
    );
  }
}

class Siparis {
  final int id;
  final double toplamTutar;
  final SiparisDurumu durum;
  final String adres;
  final DateTime olusturulma;
  final List<SiparisKalemi> kalemler;

  /// Kartın yalnızca son dört hanesi ve üzerindeki ad saklanır. Tam numara,
  /// son kullanma tarihi ve güvenlik kodu sunucuya doğrulatılır ama hiçbir
  /// yere yazılmaz; bu yüzden burada da karşılıkları yoktur.
  final String? kartSonDort;
  final String? kartSahibi;

  const Siparis({
    required this.id,
    required this.toplamTutar,
    required this.durum,
    required this.adres,
    required this.olusturulma,
    required this.kalemler,
    this.kartSonDort,
    this.kartSahibi,
  });

  String get toplamMetni => '${toplamTutar.toStringAsFixed(2)} TL';

  /// Sipariş numarası kullanıcıya "#12" yerine "SP-000012" biçiminde
  /// gösteriliyor; okunması ve telefonda söylenmesi kolay olsun diye.
  String get numara => 'SP-${id.toString().padLeft(6, '0')}';

  String get kartMetni =>
      kartSonDort == null ? 'Kart bilgisi yok' : '**** **** **** $kartSonDort';

  /// Uygulamada tarih biçimlendirme için ayrı bir paket kullanılmıyor;
  /// tek yerde gerektiği için elle yazıldı.
  String get tarihMetni {
    final yerel = olusturulma.toLocal();
    String iki(int sayi) => sayi.toString().padLeft(2, '0');

    return '${iki(yerel.day)}.${iki(yerel.month)}.${yerel.year} '
        '${iki(yerel.hour)}:${iki(yerel.minute)}';
  }

  int get toplamAdet =>
      kalemler.fold(0, (toplam, kalem) => toplam + kalem.adet);

  factory Siparis.fromJson(Map<String, dynamic> json) {
    return Siparis(
      id: json['id'] as int,
      toplamTutar: _sayiyaCevir(json['totalAmount']),
      durum: SiparisDurumu.cozumle(json['status'] as String?),
      adres: (json['addressText'] as String?) ?? '',
      olusturulma:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      kalemler: ((json['items'] as List?) ?? [])
          .map((kalem) => SiparisKalemi.fromJson(kalem as Map<String, dynamic>))
          .toList(),
      kartSonDort: json['cardLast4'] as String?,
      kartSahibi: json['cardHolderName'] as String?,
    );
  }
}

/// Sunucu para alanlarını `Decimal` tipinden metin olarak gönderir.
double _sayiyaCevir(Object? deger) {
  if (deger == null) return 0;
  if (deger is num) return deger.toDouble();
  return double.tryParse(deger.toString()) ?? 0;
}
