import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/sayfali_sonuc.dart';
import '../models/siparis.dart';

/// Sipariş uçlarına yapılan çağrılar.
///
/// Şimdilik yalnızca sipariş oluşturma var; sipariş geçmişinin listelenmesi
/// ve detayı Gün 13'te eklenecek.
class SiparisServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  /// Sepetteki ürünlerden sipariş oluşturur.
  ///
  /// Kart bilgisi sunucuya yalnızca **doğrulanmak** için gönderilir; sunucu
  /// numaranın son dört hanesi ile karttaki adı saklar, gerisini hiçbir yere
  /// yazmaz. Bu yüzden burada da kart bilgisi bir yerde tutulmaz, doğrudan
  /// istekle birlikte gider.
  ///
  /// Gerçek bir kurulumda kart bu sunucuya hiç uğramaz; uygulama kartı ödeme
  /// kuruluşuna gönderir ve sunucuya yalnızca bir jeton iletilirdi.
  Future<Siparis> olustur({
    required String adres,
    required String kartNumarasi,
    required String sonKullanma,
    required String cvv,
    required String kartSahibi,
  }) async {
    final yanit = await _istemci.dio.post(
      ApiSabitleri.siparisler,
      data: {
        'addressText': adres,
        'cardNumber': kartNumarasi,
        'cardExpiry': sonKullanma,
        'cardCvv': cvv,
        'cardHolderName': kartSahibi,
      },
    );

    return Siparis.fromJson(yanit.data as Map<String, dynamic>);
  }

  /// Kullanıcının kendi siparişleri, en yeniden eskiye.
  ///
  /// Ürün listesinin aksine sayfalama yok: sunucu düz bir dizi döndürüyor.
  /// Bir kullanıcının sipariş sayısı katalog kadar büyümediği için zarf
  /// gerekmedi.
  Future<List<Siparis>> listele() async {
    final yanit = await _istemci.dio.get(ApiSabitleri.siparisler);

    final ham = yanit.data as List<dynamic>;

    return ham
        .map((kayit) => Siparis.fromJson(kayit as Map<String, dynamic>))
        .toList();
  }

  /// Tek siparişin son hâli.
  ///
  /// Listeden gelen kayıt yeterli görünüyor ama durum sunucuda değişebiliyor
  /// (yönetici siparişi hazırlanıyor/kargoda yapıyor). Detay ekranındaki
  /// yenileme bu uçtan güncel durumu çekiyor.
  Future<Siparis> detay(int id) async {
    final yanit = await _istemci.dio.get('${ApiSabitleri.siparisler}/$id');

    return Siparis.fromJson(yanit.data as Map<String, dynamic>);
  }

  // ── Yönetici işlemleri ──────────────────────────────────────────

  /// Bütün kullanıcıların siparişleri.
  ///
  /// Kullanıcının kendi listesinin aksine bu uç sayfalı: sipariş sayısı
  /// zamanla büyüyor ve tek istekte taşınamaz. Ürün listesiyle aynı zarfı
  /// döndürdüğü için `SayfaliSonuc` yeniden kullanılıyor.
  Future<SayfaliSonuc<Siparis>> hepsiniGetir({
    SiparisDurumu? durum,
    int sayfa = 1,
    int limit = 20,
  }) async {
    final sorgu = <String, dynamic>{'page': sayfa, 'limit': limit};

    // Süzgeç seçilmemişse parametre hiç eklenmiyor; sunucu da aynı mantıkla
    // çalışıyor.
    if (durum != null) sorgu['status'] = durum.anahtar;

    final yanit = await _istemci.dio.get(
      '${ApiSabitleri.siparisler}/admin/all',
      queryParameters: sorgu,
    );

    return SayfaliSonuc.fromJson(
      yanit.data as Map<String, dynamic>,
      Siparis.fromJson,
    );
  }

  /// Siparişin durumunu değiştirir.
  ///
  /// Sunucu geçiş tablosuna uymayan istekleri 409 ile reddediyor; ekran da
  /// yalnızca izin verilen geçişleri sunuyor.
  Future<Siparis> durumGuncelle(int id, SiparisDurumu durum) async {
    final yanit = await _istemci.dio.patch(
      '${ApiSabitleri.siparisler}/$id/status',
      data: {'status': durum.anahtar},
    );

    return Siparis.fromJson(yanit.data as Map<String, dynamic>);
  }
}

/// Sipariş denemesinin sonucu: ya sipariş oluşur ya hata mesajı döner.
///
/// `AuthServisi`'ndeki `OturumSonucu` ile aynı düşünce — ekran tek bir
/// nesneye bakıp hangi yolun gerçekleştiğini anlar.
class SiparisSonucu {
  final Siparis? siparis;
  final String? hata;

  const SiparisSonucu.basarili(Siparis this.siparis) : hata = null;
  const SiparisSonucu.basarisiz(String this.hata) : siparis = null;

  bool get basarili => siparis != null;
}
