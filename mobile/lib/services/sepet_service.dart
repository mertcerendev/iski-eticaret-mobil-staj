import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Sepet uçlarına yapılan çağrılar.
///
/// Gün 10'da yalnızca "sepete ekle" gerekiyor; listeleme, adet güncelleme ve
/// silme sepet ekranıyla birlikte Gün 11'de eklenecek.
class SepetServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  /// Ürünü sepete ekler.
  ///
  /// Sunucu aynı ürün zaten sepetteyse yeni satır açmaz, adedi birleştirir
  /// (`upsert`). Stok yetersizse 409 döner; hata `hataMesaji` ile
  /// kullanıcıya gösterilebilir bir cümleye çevrilir.
  Future<void> ekle({required int urunId, required int adet}) async {
    await _istemci.dio.post(
      ApiSabitleri.sepet,
      data: {'productId': urunId, 'quantity': adet},
    );
  }
}
