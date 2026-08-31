import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/sepet.dart';
import '../services/sepet_service.dart';
import '../services/siparis_service.dart';

/// Sepetin durumunu tutar.
///
/// **Neden favorilerdeki gibi iyimser güncelleme yok?**
/// Favoride değişen tek şey bir bit'ti (dolu kalp / boş kalp); yanlışsa geri
/// almak kolaydı. Sepette ise adet değişince ara toplam ve genel toplam da
/// değişiyor, üstelik stok denetimi sunucuda. Aynı hesabı bir de burada
/// yapmak iki ayrı doğruluk kaynağı demek olurdu. Bu yüzden ekran sunucunun
/// döndürdüğü sepeti bekler; beklerken o satırın düğmeleri kapatılır.
class SepetProvider extends ChangeNotifier {
  final SepetServisi _servis = SepetServisi();

  /// Sipariş verme burada duruyor çünkü sipariş **sepeti tüketen** bir işlem:
  /// sunucu siparişi açtıktan sonra sepeti boşaltıyor, dolayısıyla sepetin
  /// durumunu tutan sınıfın bundan haberi olmak zorunda. Sipariş geçmişinin
  /// listelenmesi Gün 13'te kendi sağlayıcısına taşınacak.
  final SiparisServisi _siparisServisi = SiparisServisi();

  Sepet _sepet = const Sepet.bos();
  bool _yukleniyor = false;
  String? _hata;

  /// Sipariş isteği sürerken doğru: ödeme ekranındaki düğmeyi kilitler.
  bool _siparisVeriliyor = false;

  /// Hangi ürünün satırı için sunucuya istek gitmiş durumda. Yalnız o satır
  /// kilitlenir; kullanıcı diğer satırlarla çalışmaya devam edebilir.
  int? _islemdekiUrunId;

  Sepet get sepet => _sepet;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  bool get siparisVeriliyor => _siparisVeriliyor;

  /// Alt gezinmedeki rozetin okuduğu değer.
  int get toplamAdet => _sepet.toplamAdet;

  bool islemdeMi(int urunId) => _islemdekiUrunId == urunId;

  Future<void> yukle() async {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      _sepet = await _servis.listele();
    } catch (hata) {
      _hata = hataMesaji(hata);
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  // Aşağıdaki üç işlem de aynı kalıbı izliyor: satırı kilitle, çağrıyı yap,
  // dönen sepeti yerine koy, kilidi aç. Tek fark hangi servis metodunun
  // çağrıldığı — o yüzden ortak gövde `_islem` içinde toplandı.
  //
  // Hepsi hata mesajını **döndürür**, ekranda göstermez: kullanıcıya nasıl
  // bildirileceğine (SnackBar, yazı, vs.) ekran karar verir. Hata yoksa `null`.

  Future<String?> ekle({required int urunId, required int adet}) {
    return _islem(urunId, () => _servis.ekle(urunId: urunId, adet: adet));
  }

  Future<String?> adetDegistir({required int urunId, required int adet}) {
    return _islem(
      urunId,
      () => _servis.adetGuncelle(urunId: urunId, adet: adet),
    );
  }

  Future<String?> cikar(int urunId) {
    return _islem(urunId, () => _servis.cikar(urunId));
  }

  /// Sepetteki ürünlerden sipariş oluşturur.
  ///
  /// Sunucu tek bir transaction içinde stoğu düşürüp siparişi açıyor ve
  /// sepeti boşaltıyor. Başarılı olursa buradaki sepet de boşaltılır —
  /// yeniden listeleme isteği atmaya gerek yok, sonuç zaten kesin.
  ///
  /// Kart bilgisi hiçbir alana atanmadan doğrudan servise geçiriliyor;
  /// sağlayıcı da ekran da onu bellekte tutmuyor.
  Future<SiparisSonucu> siparisVer({
    required String adres,
    required String kartNumarasi,
    required String sonKullanma,
    required String cvv,
    required String kartSahibi,
  }) async {
    _siparisVeriliyor = true;
    notifyListeners();

    try {
      final siparis = await _siparisServisi.olustur(
        adres: adres,
        kartNumarasi: kartNumarasi,
        sonKullanma: sonKullanma,
        cvv: cvv,
        kartSahibi: kartSahibi,
      );

      _sepet = const Sepet.bos();

      return SiparisSonucu.basarili(siparis);
    } catch (hata) {
      // Sipariş açılmadıysa sunucudaki sepet de olduğu gibi duruyor
      // (transaction geri alınıyor), bu yüzden buradaki sepete dokunulmuyor.
      return SiparisSonucu.basarisiz(hataMesaji(hata));
    } finally {
      _siparisVeriliyor = false;
      notifyListeners();
    }
  }

  Future<String?> _islem(int urunId, Future<Sepet> Function() cagri) async {
    _islemdekiUrunId = urunId;
    notifyListeners();

    try {
      _sepet = await cagri();

      return null;
    } catch (hata) {
      return hataMesaji(hata);
    } finally {
      _islemdekiUrunId = null;
      notifyListeners();
    }
  }
}
