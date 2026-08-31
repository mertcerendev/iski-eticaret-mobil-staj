import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
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
