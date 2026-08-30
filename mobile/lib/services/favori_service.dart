import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/urun.dart';

/// Favori uçlarına yapılan çağrılar.
class FavoriServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  /// Kullanıcının favorileri. Sunucu her satırı ürünüyle birlikte döndürür.
  Future<List<Urun>> listele() async {
    final yanit = await _istemci.dio.get(ApiSabitleri.favoriler);

    final ham = yanit.data as List<dynamic>;

    return ham
        .map((satir) =>
            Urun.fromJson((satir as Map<String, dynamic>)['product']
                as Map<String, dynamic>))
        .toList();
  }

  /// Favori durumunu tersine çevirir: ekliyse çıkarır, değilse ekler.
  ///
  /// Sunucu tek uçla bu işi yapıyor (toggle) ve yeni durumu `favorited`
  /// alanında döndürüyor. Böylece istemcinin "şu an favoride mi" bilgisini
  /// göndermesi gerekmiyor.
  Future<bool> degistir(int urunId) async {
    final yanit = await _istemci.dio.post('${ApiSabitleri.favoriler}/$urunId');

    final govde = yanit.data as Map<String, dynamic>;

    return govde['favorited'] as bool;
  }
}
