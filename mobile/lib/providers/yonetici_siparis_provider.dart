import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/siparis.dart';
import '../services/siparis_service.dart';

/// Yöneticinin gördüğü sipariş listesi.
///
/// **Neden `SiparisProvider`'a eklenmedi?** İki liste farklı veri: biri
/// kullanıcının kendi siparişleri, diğeri bütün kullanıcılarınki. Aynı sınıfta
/// tutulsalardı hangi listenin hangi ekrana ait olduğu karışır, süzgeç ve
/// sayfa numarası gibi alanlar iki kez tekrar ederdi.
class YoneticiSiparisProvider extends ChangeNotifier {
  final SiparisServisi _servis = SiparisServisi();

  static const int _sayfaBoyutu = 20;

  final List<Siparis> _siparisler = [];

  bool _yukleniyor = false;

  /// Sonraki sayfa isteği sürerken doğru.
  ///
  /// Tam yükleme ile aynı bayrak kullanılamıyor: sayfalama bayrağı erken
  /// sıfırlanınca tazeleme sürerken yeni sayfa isteği başlayabiliyordu.
  bool _dahaYukleniyor = false;

  String? _hata;

  /// Yarışan isteklerin sonucunu ayırt eder. Süzgeç değiştirildiğinde ya da
  /// liste tazelendiğinde uçmakta olan sayfalama isteğinin geç dönen yanıtı
  /// yeni listenin altına eklenmesin diye her istek kendi sırasını taşır.
  /// `UrunProvider._istekSirasi` ile aynı çözüm.
  int _istekSirasi = 0;

  /// Seçili durum süzgeci; boşsa bütün siparişler geliyor.
  SiparisDurumu? _durumSuzgeci;

  int _sayfa = 1;
  int _toplamSayfa = 1;
  int _toplam = 0;

  /// Durumu değiştirilmekte olan siparişin kimliği. Yalnız o kartın düğmeleri
  /// kapanıyor; yönetici diğer siparişlerle çalışmaya devam edebiliyor.
  int? _guncellenenId;

  List<Siparis> get siparisler => List.unmodifiable(_siparisler);
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;
  SiparisDurumu? get durumSuzgeci => _durumSuzgeci;
  int get toplam => _toplam;
  bool get bosMu => _siparisler.isEmpty;
  bool get dahaVarMi => _sayfa < _toplamSayfa;

  bool guncelleniyorMu(int id) => _guncellenenId == id;

  /// Çıkış yapıldığında çağrılır; liste bir sonraki yöneticiye taşınmasın.
  void temizle() {
    _siparisler.clear();
    _durumSuzgeci = null;
    _sayfa = 1;
    _toplamSayfa = 1;
    _toplam = 0;
    _hata = null;
    notifyListeners();
  }

  Future<void> yukle() async {
    final sira = ++_istekSirasi;

    _yukleniyor = true;
    _hata = null;
    notifyListeners();

    try {
      final sonuc = await _servis.hepsiniGetir(
        durum: _durumSuzgeci,
        sayfa: 1,
        limit: _sayfaBoyutu,
      );

      // Bu istek beklerken yenisi başlatılmışsa sonucu yok sayılır.
      if (sira != _istekSirasi) return;

      _siparisler
        ..clear()
        ..addAll(sonuc.kayitlar);

      _sayfa = sonuc.sayfa;
      _toplamSayfa = sonuc.toplamSayfa;
      _toplam = sonuc.toplam;
    } catch (hata) {
      if (sira != _istekSirasi) return;

      _hata = hataMesaji(hata);
      _siparisler.clear();
    } finally {
      // Bayrak koşulsuz sıfırlanıyor: `sira` denetimine bağlanırsa, araya
      // yeni bir istek girdiğinde koşul tutmaz ve bayrak sonsuza kadar
      // `true` kalır. `UrunProvider.dahaFazlaYukle` içinde yaşanan tuzağın
      // aynısı.
      _yukleniyor = false;
      notifyListeners();
    }
  }

  /// Sonraki sayfayı getirip eldekilerin üzerine ekler.
  Future<void> dahaFazlaYukle() async {
    // Tazeleme sürerken sayfalama başlatılmıyor: liste birazdan sıfırdan
    // kurulacak, üzerine eklenecek sayfanın anlamı kalmaz.
    if (_dahaYukleniyor || _yukleniyor || !dahaVarMi) return;

    final sira = _istekSirasi;

    _dahaYukleniyor = true;
    notifyListeners();

    try {
      final sonuc = await _servis.hepsiniGetir(
        durum: _durumSuzgeci,
        sayfa: _sayfa + 1,
        limit: _sayfaBoyutu,
      );

      // Bu sayfa uçarken süzgeç değişmiş ya da liste tazelenmişse sonuç
      // atılıyor. Eklenseydi eski süzgecin satırları yeni listenin altına
      // yapışır, `_sayfa` ileri kayar ve yeni süzgecin o sayfası hiç
      // istenmezdi.
      if (sira != _istekSirasi) return;

      _siparisler.addAll(sonuc.kayitlar);
      _sayfa = sonuc.sayfa;
      _toplamSayfa = sonuc.toplamSayfa;
      _toplam = sonuc.toplam;
    } catch (_) {
      // Eldeki liste korunuyor; yönetici yeniden deneyebilir.
    } finally {
      _dahaYukleniyor = false;
      notifyListeners();
    }
  }

  void suzgecSec(SiparisDurumu? durum) {
    if (_durumSuzgeci == durum) return;

    _durumSuzgeci = durum;
    yukle();
  }

  /// Siparişin durumunu değiştirir ve dönen kaydı listedeki yerine koyar.
  ///
  /// Liste tümden yeniden çekilmiyor: sunucu güncel siparişi zaten
  /// döndürüyor ve yöneticinin bulunduğu sayfa kaymasın isteniyor.
  Future<String?> durumDegistir(int id, SiparisDurumu durum) async {
    _guncellenenId = id;
    notifyListeners();

    try {
      final guncel = await _servis.durumGuncelle(id, durum);

      final sira = _siparisler.indexWhere((siparis) => siparis.id == id);

      if (sira != -1) {
        // Durum güncelleme yanıtı müşteri bilgisini içermiyor; eldeki kayıttan
        // taşınıyor, yoksa kart üzerindeki müşteri satırı kaybolurdu.
        _siparisler[sira] = guncel.musteriIle(_siparisler[sira].musteri);
      }

      return null;
    } catch (hata) {
      return hataMesaji(hata);
    } finally {
      if (_guncellenenId == id) _guncellenenId = null;

      notifyListeners();
    }
  }
}
