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

  /// Sepeti değiştiren isteklerin sırası.
  ///
  /// Yalnız ilgili satır kilitlendiği için aynı anda birden fazla satır için
  /// istek uçabiliyor. Yanıtlar sırasız dönerse, eski isteğin sepeti yeni
  /// isteğin sepetini ezip ekranda eksik adet gösteriyordu. Her istek kendi
  /// sırasını taşır ve yalnız en sonuncusu sepeti yerine koyar.
  /// `UrunProvider._istekSirasi` ile aynı çözüm.
  int _istekSirasi = 0;

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

  /// Çıkış yapıldığında çağrılır. Sepet kullanıcıya ait olduğu için
  /// bellekte bırakılmaz; alt gezinmedeki rozet de böylece sıfırlanır.
  void temizle() {
    _sepet = const Sepet.bos();
    _hata = null;
    notifyListeners();
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
    final sira = ++_istekSirasi;

    _islemdekiUrunId = urunId;
    notifyListeners();

    try {
      final gelen = await cagri();

      // Bu istek beklerken başka bir satır için yenisi başlatılmışsa sonucu
      // yok sayılır: sunucunun daha yeni yanıtı bu değişikliği de içeriyor,
      // eskisini yazmak o satırın artışını ekrandan silerdi.
      if (sira == _istekSirasi) _sepet = gelen;

      return null;
    } catch (hata) {
      return hataMesaji(hata);
    } finally {
      // Kilidi yalnızca onu koyan istek açar. Koşulsuz `null` atansaydı,
      // bu istek biterken başka bir satır için başlamış olan isteğin kilidi
      // de kalkar ve o satır yanıtı gelmeden yeniden tıklanabilir olurdu.
      if (_islemdekiUrunId == urunId) _islemdekiUrunId = null;

      notifyListeners();
    }
  }
}
