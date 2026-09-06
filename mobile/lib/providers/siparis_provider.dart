import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/siparis.dart';
import '../services/siparis_service.dart';

/// Kullanıcının sipariş geçmişini tutar.
///
/// **Neden sipariş verme burada değil?** Sipariş oluşturmak sepeti tüketen bir
/// işlem; sonucu sepetin durumunu değiştirdiği için `SepetProvider` içinde
/// duruyor. Burası yalnızca geçmişi okuyor — iki sorumluluk ayrı sağlayıcıda.
class SiparisProvider extends ChangeNotifier {
  final SiparisServisi _servis = SiparisServisi();

  final List<Siparis> _siparisler = [];

  bool _yukleniyor = false;
  String? _hata;

  /// Hangi siparişin detayı yenileniyor. Yalnız o kartın/ekranın göstergesi
  /// döner; sepetteki satır kilidiyle aynı fikir.
  int? _yenilenenId;

  List<Siparis> get siparisler => List.unmodifiable(_siparisler);
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  bool get bosMu => _siparisler.isEmpty;

  bool yenileniyorMu(int id) => _yenilenenId == id;

  /// Listede id'si verilen siparişi bulur.
  ///
  /// Detay ekranı kendi kopyasını tutmuyor, her çizimde buradan okuyor.
  /// Böylece yenileme sonrası liste ve detay aynı kaydı gösteriyor —
  /// iki ayrı doğruluk kaynağı oluşmuyor.
  Siparis? bul(int id) {
    for (final siparis in _siparisler) {
      if (siparis.id == id) return siparis;
    }

    return null;
  }

  /// Çıkış yapıldığında çağrılır.
  ///
  /// Sipariş geçmişi kullanıcıya ait. Temizlenmezse çıkan kişinin
  /// siparişleri bellekte kalıyor ve ardından giren başka biri ekranı
  /// açtığında, kendi listesi sunucudan gelene kadar onları görüyordu —
  /// istek başarısız olursa kalıcı olarak.
  void temizle() {
    _siparisler.clear();
    _hata = null;
    notifyListeners();
  }

  Future<void> yukle() async {
    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      final gelen = await _servis.listele();

      _siparisler
        ..clear()
        ..addAll(gelen);
    } catch (hata) {
      _hata = hataMesaji(hata);
    } finally {
      _yukleniyor = false;
      notifyListeners();
    }
  }

  /// Tek siparişin son hâlini çeker ve listedeki kaydın yerine koyar.
  ///
  /// Hata yoksa `null` döner; ekran hatayı nasıl göstereceğine kendi karar
  /// verir.
  Future<String?> detayYenile(int id) async {
    _yenilenenId = id;
    notifyListeners();

    try {
      final guncel = await _servis.detay(id);

      final sira = _siparisler.indexWhere((siparis) => siparis.id == id);

      if (sira == -1) {
        // Liste bu arada yeniden yüklenmiş ve kayıt düşmüş olabilir.
        _siparisler.insert(0, guncel);
      } else {
        _siparisler[sira] = guncel;
      }

      return null;
    } catch (hata) {
      return hataMesaji(hata);
    } finally {
      // Kilidi yalnızca onu koyan istek açar.
      if (_yenilenenId == id) _yenilenenId = null;

      notifyListeners();
    }
  }

}
