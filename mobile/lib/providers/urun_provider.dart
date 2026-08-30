import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/kategori.dart';
import '../models/urun.dart';
import '../services/kategori_service.dart';
import '../services/urun_service.dart';

/// Ürün listesinin durumunu tutar: hangi ölçütlerle arandığı, elde hangi
/// sayfaların olduğu, yükleme ve hata hâlleri.
///
/// Ekran yalnızca bu sınıfı okur ve olayları bildirir; hangi isteğin
/// atılacağına, sayfanın sıfırlanıp sıfırlanmayacağına burası karar verir.
class UrunProvider extends ChangeNotifier {
  final UrunServisi _urunServisi = UrunServisi();
  final KategoriServisi _kategoriServisi = KategoriServisi();

  /// Kullanıcı yazarken her harfte istek atılmaması için beklenen süre.
  static const Duration _aramaGecikmesi = Duration(milliseconds: 500);

  static const int _sayfaBoyutu = 10;

  final List<Urun> _urunler = [];
  final List<Kategori> _kategoriler = [];

  bool _ilkYuklemeSuruyor = true;
  bool _dahaYukleniyor = false;
  String? _hata;

  String _arama = '';
  int? _seciliKategoriId;
  Siralama _siralama = Siralama.yeni;

  int _sayfa = 1;
  int _toplamSayfa = 1;
  int _toplam = 0;

  Timer? _aramaSayaci;

  /// Yarışan isteklerin sonucunu ayırt etmek için kullanılır. Kullanıcı
  /// hızlıca filtre değiştirirse eski isteğin geç dönen yanıtı listeyi
  /// bozmasın diye her istek kendi sırasını taşır.
  int _istekSirasi = 0;

  List<Urun> get urunler => List.unmodifiable(_urunler);
  List<Kategori> get kategoriler => List.unmodifiable(_kategoriler);

  bool get ilkYuklemeSuruyor => _ilkYuklemeSuruyor;
  bool get dahaYukleniyor => _dahaYukleniyor;
  String? get hata => _hata;

  String get arama => _arama;
  int? get seciliKategoriId => _seciliKategoriId;
  Siralama get siralama => _siralama;
  int get toplam => _toplam;

  bool get bosMu =>
      !_ilkYuklemeSuruyor && _hata == null && _urunler.isEmpty;

  bool get dahaVarMi => _sayfa < _toplamSayfa;

  bool get suzgecUygulandi => _arama.isNotEmpty || _seciliKategoriId != null;

  @override
  void dispose() {
    _aramaSayaci?.cancel();
    super.dispose();
  }

  /// Ekran ilk açıldığında bir kez çağrılır.
  Future<void> baslat() async {
    await Future.wait([
      _kategorileriYukle(),
      yenidenYukle(),
    ]);
  }

  /// Arama kutusuna her harf girildiğinde çağrılır ama istek hemen atılmaz.
  ///
  /// Sayaç her tuşta sıfırlanır; kullanıcı yazmayı bırakıp yarım saniye
  /// beklediğinde tek istek gider. Buna *debounce* denir — "kulaklık"
  /// yazarken 8 istek yerine 1 istek atılır.
  void aramaDegisti(String metin) {
    _arama = metin;
    notifyListeners();

    _aramaSayaci?.cancel();
    _aramaSayaci = Timer(_aramaGecikmesi, yenidenYukle);
  }

  void kategoriSec(int? kategoriId) {
    if (_seciliKategoriId == kategoriId) return;

    _seciliKategoriId = kategoriId;
    yenidenYukle();
  }

  void siralamaSec(Siralama yeni) {
    if (_siralama == yeni) return;

    _siralama = yeni;
    yenidenYukle();
  }

  void suzgecleriTemizle() {
    _arama = '';
    _seciliKategoriId = null;
    _aramaSayaci?.cancel();
    yenidenYukle();
  }

  /// Ölçütler değiştiğinde listeyi baştan kurar: sayfa 1'e döner ve
  /// eldeki kayıtlar atılır.
  Future<void> yenidenYukle() async {
    final sira = ++_istekSirasi;

    _ilkYuklemeSuruyor = true;
    _hata = null;
    notifyListeners();

    try {
      final sonuc = await _urunServisi.listele(
        arama: _arama,
        kategoriId: _seciliKategoriId,
        siralama: _siralama,
        sayfa: 1,
        limit: _sayfaBoyutu,
      );

      // Bu istek beklerken yenisi başlatılmışsa sonucu yok say.
      if (sira != _istekSirasi) return;

      _urunler
        ..clear()
        ..addAll(sonuc.kayitlar);

      _sayfa = sonuc.sayfa;
      _toplamSayfa = sonuc.toplamSayfa;
      _toplam = sonuc.toplam;
    } catch (hata) {
      if (sira != _istekSirasi) return;

      _hata = hataMesaji(hata);
      _urunler.clear();
    } finally {
      if (sira == _istekSirasi) {
        _ilkYuklemeSuruyor = false;
        notifyListeners();
      }
    }
  }

  /// Liste sonuna yaklaşıldığında çağrılır. Sonraki sayfayı getirir ve
  /// eldekilerin üzerine ekler.
  Future<void> dahaFazlaYukle() async {
    // Zaten yükleniyorsa ya da son sayfadaysak istek atma.
    if (_dahaYukleniyor || !dahaVarMi || _ilkYuklemeSuruyor) return;

    final sira = _istekSirasi;

    _dahaYukleniyor = true;
    notifyListeners();

    try {
      final sonuc = await _urunServisi.listele(
        arama: _arama,
        kategoriId: _seciliKategoriId,
        siralama: _siralama,
        sayfa: _sayfa + 1,
        limit: _sayfaBoyutu,
      );

      if (sira != _istekSirasi) return;

      _urunler.addAll(sonuc.kayitlar);
      _sayfa = sonuc.sayfa;
      _toplamSayfa = sonuc.toplamSayfa;
      _toplam = sonuc.toplam;
    } catch (_) {
      // Sonraki sayfa gelmezse eldeki liste korunur; kullanıcı yeniden
      // kaydırarak tekrar deneyebilir. Ekranı hataya çevirmek, çalışan
      // listeyi kaybettireceği için tercih edilmedi.
    } finally {
      if (sira == _istekSirasi) {
        _dahaYukleniyor = false;
        notifyListeners();
      }
    }
  }

  Future<void> _kategorileriYukle() async {
    try {
      final gelen = await _kategoriServisi.hepsiniGetir();

      _kategoriler
        ..clear()
        ..addAll(gelen);

      notifyListeners();
    } catch (_) {
      // Kategoriler gelmezse filtre çipleri görünmez ama ürün listesi
      // çalışmaya devam eder. Bu yüzden hata ekrana taşınmaz.
    }
  }
}
