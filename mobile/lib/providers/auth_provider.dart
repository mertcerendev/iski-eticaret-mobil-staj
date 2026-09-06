import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/kullanici.dart';
import '../services/auth_service.dart';

/// Uygulamanın açılıştaki üç olası oturum hâli.
enum OturumDurumu { kontrolEdiliyor, cikisYapildi, girisYapildi }

/// Oturum bilgisini tutan ve değiştiğinde dinleyicilere haber veren sınıf.
///
/// `ChangeNotifier`'dan türer: durum değişince `notifyListeners()` çağrılır,
/// bu sınıfı dinleyen widget'lar kendini yeniden çizer. Böylece giriş
/// bilgisi ekrandan ekrana parametre olarak taşınmaz.
class AuthProvider extends ChangeNotifier {
  final AuthServisi _servis = AuthServisi();
  final ApiIstemcisi _istemci = ApiIstemcisi();

  OturumDurumu _durum = OturumDurumu.kontrolEdiliyor;
  Kullanici? _kullanici;
  bool _islemSuruyor = false;
  String? _hata;

  AuthProvider() {
    // Sunucu 401 döndüğünde istemci bu geri çağrımı tetikler; oturum
    // tek yerden düşürülür.
    _istemci.oturumDustu = _oturumuDusur;
  }

  OturumDurumu get durum => _durum;
  Kullanici? get kullanici => _kullanici;
  bool get islemSuruyor => _islemSuruyor;
  String? get hata => _hata;

  bool get girisYapildi => _durum == OturumDurumu.girisYapildi;
  bool get yoneticiMi => _kullanici?.yoneticiMi ?? false;

  /// Uygulama açılışında bir kez çalışır.
  ///
  /// Kayıtlı token varsa sunucuya sorulur. Geçerliyse kullanıcı doğrudan
  /// içeri alınır — her açılışta yeniden giriş yapmak gerekmez.
  Future<void> acilistaKontrolEt() async {
    final token = await _istemci.tokenOku();

    if (token == null || token.isEmpty) {
      _durum = OturumDurumu.cikisYapildi;
      notifyListeners();
      return;
    }

    try {
      _kullanici = await _servis.profilGetir();
      _durum = OturumDurumu.girisYapildi;
    } catch (_) {
      // Token süresi dolmuş ya da sunucuya ulaşılamıyor. Her iki durumda
      // da kullanıcıyı giriş ekranına almak doğru davranış.
      await _istemci.tokenSil();
      _kullanici = null;
      _durum = OturumDurumu.cikisYapildi;
    }

    notifyListeners();
  }

  Future<bool> girisYap({
    required String eposta,
    required String parola,
  }) {
    return _oturumAc(
      () => _servis.girisYap(eposta: eposta, parola: parola),
    );
  }

  Future<bool> kayitOl({
    required String eposta,
    required String parola,
    required String adSoyad,
  }) {
    return _oturumAc(
      () => _servis.kayitOl(eposta: eposta, parola: parola, adSoyad: adSoyad),
    );
  }

  Future<void> cikisYap() async {
    await _istemci.tokenSil();
    _oturumuDusur();
  }

  /// Adı günceller; başarılıysa bellekteki kullanıcı da tazelenir.
  ///
  /// Hata mesajını döndürür, hata yoksa `null`. Ekran nasıl göstereceğine
  /// kendisi karar verir.
  Future<String?> profilGuncelle(String adSoyad) {
    return _islem(() async {
      _kullanici = await _servis.profilGuncelle(adSoyad);
    });
  }

  /// Parolayı değiştirir.
  ///
  /// Oturum düşürülmüyor: sunucu token'ı geçersiz kılmıyor, kullanıcı da
  /// çalışmasına kaldığı yerden devam edebiliyor.
  Future<String?> parolaDegistir({
    required String mevcutParola,
    required String yeniParola,
  }) {
    return _islem(
      () => _servis.parolaDegistir(
        mevcutParola: mevcutParola,
        yeniParola: yeniParola,
      ),
    );
  }

  /// Profil ve parola işlemlerinin ortak gövdesi: işaretle, çağır, hata
  /// mesajını döndür, işareti kaldır. Tek fark hangi servis metodunun
  /// çağrıldığı. `_oturumAc` ile aynı kalıp.
  Future<String?> _islem(Future<void> Function() cagri) async {
    _islemSuruyor = true;
    notifyListeners();

    try {
      await cagri();

      return null;
    } catch (hata) {
      return hataMesaji(hata);
    } finally {
      _islemSuruyor = false;
      notifyListeners();
    }
  }

  void hatayiTemizle() {
    if (_hata == null) return;
    _hata = null;
    notifyListeners();
  }

  /// Giriş ve kayıt aynı adımları izler: yükleniyor işaretle, çağrıyı yap,
  /// token'ı sakla, durumu güncelle. Tek fark hangi servis çağrıldığı —
  /// o yüzden ortak gövde burada toplanır.
  Future<bool> _oturumAc(Future<OturumSonucu> Function() cagri) async {
    _islemSuruyor = true;
    _hata = null;
    notifyListeners();

    try {
      final sonuc = await cagri();

      await _istemci.tokenYaz(sonuc.token);

      _kullanici = sonuc.kullanici;
      _durum = OturumDurumu.girisYapildi;

      return true;
    } catch (hata) {
      _hata = hataMesaji(hata);

      return false;
    } finally {
      _islemSuruyor = false;
      notifyListeners();
    }
  }

  void _oturumuDusur() {
    _kullanici = null;
    _durum = OturumDurumu.cikisYapildi;
    notifyListeners();
  }
}
