import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/sayfali_sonuc.dart';
import '../models/urun.dart';

/// Sunucunun kabul ettiği sıralama seçenekleri.
///
/// Sunucu tarafında da beyaz liste var; buradaki değerler oradaki
/// anahtarlarla birebir aynı olmak zorunda.
enum Siralama {
  yeni('yeni', 'En Yeni'),
  ucuz('ucuz', 'Fiyat: Artan'),
  pahali('pahali', 'Fiyat: Azalan'),
  isim('isim', 'İsme Göre');

  const Siralama(this.anahtar, this.etiket);

  /// Sunucuya `?sort=` olarak gidecek değer.
  final String anahtar;

  /// Menüde görünecek metin.
  final String etiket;
}

/// Ürün uçlarına yapılan çağrılar.
class UrunServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  /// Arama, kategori filtresi, sıralama ve sayfalama tek uçtan yürür.
  ///
  /// Boş bırakılan ölçütler sorguya hiç eklenmez; sunucu da aynı mantıkla
  /// süzgeci adım adım kuruyor.
  Future<SayfaliSonuc<Urun>> listele({
    String? arama,
    int? kategoriId,
    Siralama siralama = Siralama.yeni,
    int sayfa = 1,
    int limit = 10,
  }) async {
    final sorgu = <String, dynamic>{
      'sort': siralama.anahtar,
      'page': sayfa,
      'limit': limit,
    };

    if (arama != null && arama.trim().isNotEmpty) {
      sorgu['search'] = arama.trim();
    }

    if (kategoriId != null) {
      sorgu['categoryId'] = kategoriId;
    }

    final yanit = await _istemci.dio.get(
      ApiSabitleri.urunler,
      queryParameters: sorgu,
    );

    return SayfaliSonuc.fromJson(
      yanit.data as Map<String, dynamic>,
      Urun.fromJson,
    );
  }

  Future<Urun> detay(int id) async {
    final yanit = await _istemci.dio.get('${ApiSabitleri.urunler}/$id');

    return Urun.fromJson(yanit.data as Map<String, dynamic>);
  }
}
