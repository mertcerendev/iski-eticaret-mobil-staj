import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Ürün görselinin sunucuya yüklenmesi.
///
/// **Neden ayrı bir servis?** Diğer bütün isteklerin gövdesi JSON; bu istek
/// `multipart/form-data` gönderiyor. Dosya ikili (binary) veri olduğu için
/// JSON'a sığmaz — metne çevrilmesi gerekir ve boyutu üçte bir büyürdü.
/// Farklı gövde biçimi kullanan tek uç bu olduğu için kendi dosyasında duruyor.
class GorselServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  /// Sunucunun kabul ettiği en büyük dosya boyutu (multer ayarı ile aynı).
  static const int enFazlaBayt = 2 * 1024 * 1024;

  /// Sunucunun kabul ettiği uzantılar (multer'daki mime listesinin karşılığı).
  static const List<String> izinliUzantilar = ['png', 'jpg', 'jpeg', 'webp'];

  /// Dosyayı yükler ve sunucunun döndürdüğü göreli adresi verir
  /// (`/uploads/urun-....png`).
  ///
  /// Dönen adres göreli; tam adrese çevirme işini `ApiSabitleri` yapıyor.
  Future<String> yukle(String dosyaYolu) async {
    // Alan adı 'image' olmak zorunda: sunucuda `yukle.single('image')`
    // tam olarak bu adı bekliyor, başka bir adla gelen dosya görülmez.
    final govde = FormData.fromMap({
      'image': await MultipartFile.fromFile(dosyaYolu),
    });

    final yanit = await _istemci.dio.post(
      ApiSabitleri.gorselYukle,
      data: govde,
      // Content-Type başlığı istemcide varsayılan olarak JSON. Multipart
      // isteğinde Dio'nun kendi sınır (boundary) değerini üretebilmesi için
      // bu istekte başlık ezilir.
      options: Options(contentType: 'multipart/form-data'),
    );

    final sonuc = yanit.data as Map<String, dynamic>;

    return sonuc['url'] as String;
  }
}
