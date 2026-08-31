import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/sepet.dart';
import '../services/sepet_service.dart';

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

  Sepet _sepet = const Sepet.bos();
  bool _yukleniyor = false;
  String? _hata;

  /// Hangi ürünün satırı için sunucuya istek gitmiş durumda. Yalnız o satır
  /// kilitlenir; kullanıcı diğer satırlarla çalışmaya devam edebilir.
  int? _islemdekiUrunId;

  Sepet get sepet => _sepet;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

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
