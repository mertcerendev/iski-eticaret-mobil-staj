import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/urun.dart';
import '../services/favori_service.dart';

/// Favori ürünlerin durumunu tutar.
///
/// İki ayrı veri saklanır:
/// - [_favoriIdleri]: kartlardaki kalbin dolu mu boş mu çizileceğini
///   sabit sürede söyleyebilmek için. Liste üzerinde arama yapmak yerine
///   küme kullanılır.
/// - [_favoriUrunler]: favoriler ekranında gösterilecek tam ürün bilgisi.
class FavoriProvider extends ChangeNotifier {
  final FavoriServisi _servis = FavoriServisi();

  final Set<int> _favoriIdleri = {};
  final List<Urun> _favoriUrunler = [];

  bool _yukleniyor = false;
  String? _hata;

  List<Urun> get favoriUrunler => List.unmodifiable(_favoriUrunler);
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  int get adet => _favoriIdleri.length;

  bool favoriMi(int urunId) => _favoriIdleri.contains(urunId);

  Future<void> yukle() async {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      final gelen = await _servis.listele();

      _favoriUrunler
        ..clear()
        ..addAll(gelen);

      _favoriIdleri
        ..clear()
        ..addAll(gelen.map((urun) => urun.id));
    } catch (hata) {
      _hata = hataMesaji(hata);
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  /// Çıkış yapıldığında çağrılır.
  ///
  /// Şart: veriler kullanıcıya ait. Temizlenmezse çıkış yapan kişinin
  /// favorileri ekranda kalır, kartlardaki kalpler dolu görünür ve
  /// ardından giriş yapan başka biri onları kendi favorisi sanır.
  void temizle() {
    _favoriIdleri.clear();
    _favoriUrunler.clear();
    _hata = null;
    notifyListeners();
  }

  /// Favori durumunu tersine çevirir.
  ///
  /// **İyimser güncelleme (optimistic UI):** kalp, sunucunun yanıtı
  /// beklenmeden hemen doluyor. Ağ gecikmesi 50-200 ms olsa bile kullanıcı
  /// dokunuşun anında karşılık bulduğunu görür.
  ///
  /// İstek başarısız olursa değişiklik geri alınır ve hata mesajı döndürülür;
  /// ekran bunu kullanıcıya gösterir. Böylece hız kazanılırken yanlış bilgi
  /// ekranda kalmaz.
  ///
  /// Hata yoksa `null` döner.
  Future<String?> degistir(Urun urun) async {
    final oncekiDurum = _favoriIdleri.contains(urun.id);

    // 1. Ekranı hemen güncelle.
    _yereldeDegistir(urun, favori: !oncekiDurum);
    notifyListeners();

    try {
      // 2. Sunucuya bildir.
      final sunucuDurumu = await _servis.degistir(urun.id);

      // Sunucu farklı bir sonuç döndürdüyse (örneğin başka cihazdan
      // değiştirilmişse) doğru kabul edilen sunucudur.
      if (sunucuDurumu != !oncekiDurum) {
        _yereldeDegistir(urun, favori: sunucuDurumu);
        notifyListeners();
      }

      return null;
    } catch (hata) {
      // 3. Başarısızsa geri al.
      _yereldeDegistir(urun, favori: oncekiDurum);
      notifyListeners();

      return hataMesaji(hata);
    }
  }

  void _yereldeDegistir(Urun urun, {required bool favori}) {
    if (favori) {
      _favoriIdleri.add(urun.id);

      if (!_favoriUrunler.any((kayit) => kayit.id == urun.id)) {
        _favoriUrunler.insert(0, urun);
      }
    } else {
      _favoriIdleri.remove(urun.id);
      _favoriUrunler.removeWhere((kayit) => kayit.id == urun.id);
    }
  }
}
