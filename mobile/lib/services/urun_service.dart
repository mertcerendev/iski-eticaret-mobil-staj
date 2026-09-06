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

  // ── Yönetici işlemleri ──────────────────────────────────────────
  // Üç uç da sunucuda `requireAdmin` ile korunuyor. İstemci tarafında
  // düğmeleri gizlemek yalnızca görünüm kolaylığı; asıl denetim sunucuda.

  /// Ürünü kaydeder: [id] boşsa yeni kayıt açar, doluysa onu günceller.
  ///
  /// İkisi birebir aynı gövdeyi gönderiyordu; ayrı yazıldıklarında alan
  /// listesi iki yerde tekrar ediyor, birine eklenen alan diğerinde
  /// unutulabiliyordu. Tek fark HTTP metodu ve adres.
  ///
  /// Fiyat sunucuya **metin** olarak gidiyor: `Decimal` alanına yazılırken
  /// kuruş hassasiyeti kaybolmasın diye.
  Future<Urun> kaydet({
    int? id,
    required String ad,
    required String aciklama,
    required String fiyat,
    required int stok,
    required int kategoriId,
    String? gorselUrl,
  }) async {
    final govde = {
      'name': ad,
      'description': aciklama,
      'price': fiyat,
      'stock': stok,
      'categoryId': kategoriId,
      'imageUrl': gorselUrl,
    };

    final yanit = id == null
        ? await _istemci.dio.post(ApiSabitleri.urunler, data: govde)
        : await _istemci.dio.put('${ApiSabitleri.urunler}/$id', data: govde);

    return Urun.fromJson(yanit.data as Map<String, dynamic>);
  }

  /// Ürünü satıştan kaldırır.
  ///
  /// Sunucuda kayıt gerçekten silinmiyor, `isActive` alanı `false` yapılıyor.
  /// Geçmiş siparişler bu ürüne bağlı olduğu için gerçek silme veritabanı
  /// kısıtı tarafından reddedilirdi.
  Future<void> sil(int id) async {
    await _istemci.dio.delete('${ApiSabitleri.urunler}/$id');
  }
}
