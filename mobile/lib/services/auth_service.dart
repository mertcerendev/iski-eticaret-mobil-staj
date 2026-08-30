import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/kullanici.dart';

/// Kayıt ve giriş uçlarının döndürdüğü ikili: kullanıcı bilgisi + token.
class OturumSonucu {
  final Kullanici kullanici;
  final String token;

  const OturumSonucu({required this.kullanici, required this.token});
}

/// Kimlik doğrulama uçlarına yapılan çağrılar.
///
/// Bu sınıf yalnızca sunucuyla konuşur; ekranı ya da durumu bilmez.
/// Backend'deki `service` katmanının HTTP bilmemesi ile aynı ayrım.
class AuthServisi {
  final ApiIstemcisi _istemci = ApiIstemcisi();

  Future<OturumSonucu> kayitOl({
    required String eposta,
    required String parola,
    required String adSoyad,
  }) async {
    final yanit = await _istemci.dio.post(
      ApiSabitleri.kayit,
      data: {
        'email': eposta,
        'password': parola,
        'fullName': adSoyad,
      },
    );

    return _oturumuCoz(yanit.data as Map<String, dynamic>);
  }

  Future<OturumSonucu> girisYap({
    required String eposta,
    required String parola,
  }) async {
    final yanit = await _istemci.dio.post(
      ApiSabitleri.giris,
      data: {
        'email': eposta,
        'password': parola,
      },
    );

    return _oturumuCoz(yanit.data as Map<String, dynamic>);
  }

  /// Elde kayıtlı token ile kullanıcının hâlâ geçerli olup olmadığını
  /// sorar. Token içindeki bilgiye güvenilmez; kullanıcı adını değiştirmiş
  /// ya da hesabı silinmiş olabilir. Doğru kaynak her zaman sunucudur.
  Future<Kullanici> profilGetir() async {
    final yanit = await _istemci.dio.get(ApiSabitleri.profil);

    return Kullanici.fromJson(yanit.data as Map<String, dynamic>);
  }

  OturumSonucu _oturumuCoz(Map<String, dynamic> govde) {
    return OturumSonucu(
      kullanici: Kullanici.fromJson(govde['user'] as Map<String, dynamic>),
      token: govde['token'] as String,
    );
  }
}
