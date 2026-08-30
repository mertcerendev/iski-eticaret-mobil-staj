import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// Uygulamanın tek HTTP istemcisi.
///
/// Tek örnek (singleton) olmasının sebebi: token'ı ekleyen interceptor bir
/// kez kurulsun, her servis aynı ayarlı `Dio` nesnesini paylaşsın. Backend'de
/// `lib/prisma.js`'in tek bağlantıyı paylaştırması ile aynı mantık.
class ApiIstemcisi {
  static final ApiIstemcisi _ornek = ApiIstemcisi._icten();

  factory ApiIstemcisi() => _ornek;

  late final Dio dio;

  final FlutterSecureStorage _depo = FlutterSecureStorage();

  static const String _tokenAnahtari = 'oturum_token';

  /// Sunucu 401 döndüğünde çalıştırılır. `AuthProvider` bunu doldurur ve
  /// kullanıcıyı giriş ekranına yönlendirir.
  void Function()? oturumDustu;

  ApiIstemcisi._icten() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiSabitleri.temelAdres,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // Her isteğe token'ı tek yerden ekler. Servislerin tek tek başlık
        // yazmasına gerek kalmaz.
        onRequest: (secenekler, devam) async {
          final token = await tokenOku();

          if (token != null && token.isNotEmpty) {
            secenekler.headers['Authorization'] = 'Bearer $token';
          }

          devam.next(secenekler);
        },

        // Token süresi dolmuş ya da geçersizse oturumu düşür.
        onError: (hata, devam) async {
          if (hata.response?.statusCode == 401) {
            await tokenSil();
            oturumDustu?.call();
          }

          devam.next(hata);
        },
      ),
    );
  }

  // ── Token saklama ───────────────────────────────────────────────
  // Düz metin yerine güvenli depo kullanılır: Android'de Keystore,
  // iOS'ta Keychain. Token bir kimlik belgesidir, açıkta durmamalıdır.

  Future<void> tokenYaz(String token) =>
      _depo.write(key: _tokenAnahtari, value: token);

  Future<String?> tokenOku() => _depo.read(key: _tokenAnahtari);

  Future<void> tokenSil() => _depo.delete(key: _tokenAnahtari);
}

/// Sunucudan ya da ağdan gelen hatayı kullanıcıya gösterilebilir bir
/// cümleye çevirir.
///
/// Backend her hatayı `{ "message": "..." }` biçiminde döndürdüğü için
/// önce o alan aranır; bulunamazsa hatanın türüne göre genel bir mesaj
/// üretilir.
String hataMesaji(Object hata) {
  if (hata is DioException) {
    final govde = hata.response?.data;

    if (govde is Map && govde['message'] is String) {
      return govde['message'] as String;
    }

    switch (hata.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Sunucu yanıt vermedi. Bağlantınızı kontrol edin.';

      case DioExceptionType.connectionError:
        return 'Sunucuya bağlanılamadı. Sunucunun çalıştığından emin olun.';

      default:
        return 'Beklenmeyen bir hata oluştu.';
    }
  }

  return 'Beklenmeyen bir hata oluştu.';
}
