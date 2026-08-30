import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/kategori.dart';

/// Kategori uçlarına yapılan çağrılar.
class KategoriServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  /// Sunucu kategorileri düz bir dizi olarak döndürür; sayfalama yoktur.
  Future<List<Kategori>> hepsiniGetir() async {
    final yanit = await _istemci.dio.get(ApiSabitleri.kategoriler);

    final ham = yanit.data as List<dynamic>;

    return ham
        .map((kayit) => Kategori.fromJson(kayit as Map<String, dynamic>))
        .toList();
  }
}
