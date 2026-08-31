import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/sepet.dart';

/// Sepet uçlarına yapılan çağrılar.
///
/// Dört uç da yanıt olarak **sepetin tamamını** döndürüyor. Bu yüzden her
/// metodun dönüş tipi `Sepet`: sağlayıcı elindeki sepeti gelenle değiştirir,
/// ayrıca bir listeleme isteği atmasına gerek kalmaz.
class SepetServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  Future<Sepet> listele() async {
    final yanit = await _istemci.dio.get(ApiSabitleri.sepet);

    return Sepet.fromJson(yanit.data as Map<String, dynamic>);
  }

  /// Ürünü sepete ekler.
  ///
  /// Sunucu aynı ürün zaten sepetteyse yeni satır açmaz, adedi birleştirir
  /// (`upsert`). Stok yetersizse 409 döner.
  Future<Sepet> ekle({required int urunId, required int adet}) async {
    final yanit = await _istemci.dio.post(
      ApiSabitleri.sepet,
      data: {'productId': urunId, 'quantity': adet},
    );

    return Sepet.fromJson(yanit.data as Map<String, dynamic>);
  }

  /// Satırdaki adedi verilen değere **eşitler** (ekleme değil, atama).
  Future<Sepet> adetGuncelle({required int urunId, required int adet}) async {
    final yanit = await _istemci.dio.put(
      '${ApiSabitleri.sepet}/$urunId',
      data: {'quantity': adet},
    );

    return Sepet.fromJson(yanit.data as Map<String, dynamic>);
  }

  Future<Sepet> cikar(int urunId) async {
    final yanit = await _istemci.dio.delete('${ApiSabitleri.sepet}/$urunId');

    return Sepet.fromJson(yanit.data as Map<String, dynamic>);
  }
}
