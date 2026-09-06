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

  /// Ana ekrandaki keşif şeritleri.
  ///
  /// İkisi de ana listeden bağımsız, küçük ve tek seferlik isteklerle
  /// dolduruluyor. Ana liste kullanıcının süzgeçlerine göre değişiyor;
  /// şeritler ise sabit kalmalı ki kullanıcı arama yaptığında keşif içeriği
  /// altından kaymasın.
  ///
  /// **Neden "Çok Satanlar" yok?** Satış adedi verisi sunucuda toplanmıyor.
  /// Uydurma bir sıralamayı "çok satan" diye sunmak yerine, elimizdeki
  /// veriyle doğru olan iki başlık seçildi.
  final List<Urun> _yeniUrunler = [];
  final List<Urun> _uygunUrunler = [];

  static const int _seritBoyutu = 8;

  bool _ilkYuklemeSuruyor = true;
  bool _dahaYukleniyor = false;
  String? _hata;

  String _arama = '';
  int? _seciliKategoriId;
  Siralama _siralama = Siralama.yeni;

  int _sayfa = 1;
  int _toplamSayfa = 1;
  int _toplam = 0;

  /// Yönetici işlemi (ekleme/güncelleme/silme) sürerken doğru; form ve
  /// onay penceresindeki düğmeleri kilitler.
  bool _yoneticiIslemi = false;

  Timer? _aramaSayaci;

  /// Yarışan isteklerin sonucunu ayırt etmek için kullanılır. Kullanıcı
  /// hızlıca filtre değiştirirse eski isteğin geç dönen yanıtı listeyi
  /// bozmasın diye her istek kendi sırasını taşır.
  int _istekSirasi = 0;

  List<Urun> get urunler => List.unmodifiable(_urunler);
  List<Kategori> get kategoriler => List.unmodifiable(_kategoriler);
  List<Urun> get yeniUrunler => List.unmodifiable(_yeniUrunler);
  List<Urun> get uygunUrunler => List.unmodifiable(_uygunUrunler);

  /// Keşif şeritleri yalnızca kullanıcı arama ya da süzgeç uygulamadığında
  /// gösteriliyor; arama yapılırken ekranın sonuçlara ayrılması gerekiyor.
  bool get kesifGosterilsin => !suzgecUygulandi && _yeniUrunler.isNotEmpty;

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

  bool get yoneticiIslemi => _yoneticiIslemi;

  @override
  void dispose() {
    _aramaSayaci?.cancel();
    super.dispose();
  }

  /// Ekran ilk açıldığında bir kez çağrılır.
  Future<void> baslat() async {
    await Future.wait([_kategorileriYukle(), tazele()]);
  }

  /// Ana ekranın tamamını yeniler: hem keşif şeritleri hem ürün listesi.
  ///
  /// Şeritler `yenidenYukle` içine konmadı; o metot her süzgeç değişiminde
  /// ve her aramada çalışıyor, şeritlerin ise sabit kalması gerekiyor.
  /// Ama şeritler de bir yerde tazelenmeliydi: yalnız açılışta doldurulunca
  /// yönetici bir ürünü sildiğinde ızgaradan kalkıyor, şeritte kalmaya
  /// devam ediyordu — üstelik oradan açılan detay artık var olmayan bir
  /// ürünü gösteriyordu.
  Future<void> tazele() async {
    await Future.wait([_seritleriYukle(), yenidenYukle()]);
  }

  /// Keşif şeritlerini bir kez doldurur.
  ///
  /// İki istek aynı anda gidiyor. Hata durumunda şeritler gizleniyor ama ana
  /// liste çalışmaya devam ediyor; keşif içeriği vazgeçilebilir bir katman.
  Future<void> _seritleriYukle() async {
    Future<List<Urun>> getir(Siralama siralama) async {
      final sonuc = await _urunServisi.listele(
        siralama: siralama,
        sayfa: 1,
        limit: _seritBoyutu,
      );

      return sonuc.kayitlar;
    }

    try {
      final sonuclar = await Future.wait([
        getir(Siralama.yeni),
        getir(Siralama.ucuz),
      ]);

      _yeniUrunler
        ..clear()
        ..addAll(sonuclar[0]);

      _uygunUrunler
        ..clear()
        ..addAll(sonuclar[1]);

      notifyListeners();
    } catch (_) {
      // Şeritler gelmezse ana liste yine çalışıyor; hata ekrana taşınmıyor.
    }
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
      // Bayrak yalnızca bu isteğe ait, koşulsuz sıfırlanır. `sira` denetimine
      // bağlanırsa şu tuzak doğuyordu: istek uçarken `yenidenYukle` çalışınca
      // koşul tutmaz, bayrak `true` kalır ve yukarıdaki bekçi bir daha bu
      // gövdeye girilmesine izin vermediği için sonsuz kaydırma kalıcı olarak
      // durur — listenin altındaki halka da hiç kaybolmaz.
      _dahaYukleniyor = false;
      notifyListeners();
    }
  }

  // ── Yönetici işlemleri ──────────────────────────────────────────
  // Üçü de aynı kalıbı izliyor: kilitle, çağır, listeyi tazele, kilidi aç.
  // Hata mesajını **döndürüyorlar**, ekranda göstermiyorlar.
  //
  // İşlem bitince `yenidenYukle` çağrılıyor: eklenen ürün listede görünsün,
  // güncellenen ürünün yeni fiyatı yansısın, silinen ürün kaybolsun. Yerel
  // listeyi elle düzenlemek daha hızlı olurdu ama sıralama ve süzgeç
  // ölçütleri sunucuda uygulandığı için ürünün listede nereye gireceğini
  // istemci bilemez.

  /// [id] boşsa ürün ekler, doluysa günceller. Formdaki "düzenleme mi"
  /// ayrımı zaten bu tek alanla yapılıyor.
  Future<String?> urunKaydet({
    int? id,
    required String ad,
    required String aciklama,
    required String fiyat,
    required int stok,
    required int kategoriId,
    String? gorselUrl,
  }) {
    return _yoneticiIslem(
      () => _urunServisi.kaydet(
        id: id,
        ad: ad,
        aciklama: aciklama,
        fiyat: fiyat,
        stok: stok,
        kategoriId: kategoriId,
        gorselUrl: gorselUrl,
      ),
    );
  }

  Future<String?> urunSil(int id) {
    return _yoneticiIslem(() => _urunServisi.sil(id));
  }

  Future<String?> _yoneticiIslem(Future<void> Function() cagri) async {
    _yoneticiIslemi = true;
    notifyListeners();

    try {
      await cagri();

      // Liste ve keşif şeritleri sunucudan yeniden çekiliyor; `tazele`
      // kendi içinde `notifyListeners` çağırıyor.
      await tazele();

      return null;
    } catch (hata) {
      return hataMesaji(hata);
    } finally {
      _yoneticiIslemi = false;
      notifyListeners();
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
