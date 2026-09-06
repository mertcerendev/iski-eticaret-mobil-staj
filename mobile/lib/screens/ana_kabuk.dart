import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favori_provider.dart';
import '../providers/sepet_provider.dart';
import 'ana_ekran.dart';
import 'favoriler_ekrani.dart';
import 'profil_ekrani.dart';
import 'sepet_ekrani.dart';

/// Uygulamanın dört sekmeli kabuğu.
///
/// Gün 10'a kadar favorilere ve çıkışa ana sayfanın başlık çubuğundaki
/// simgelerden gidiliyordu. Sekme sayısı artınca alt gezinme çubuğuna
/// geçildi: bölümler her ekranda aynı yerde duruyor.
class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key});

  @override
  State<AnaKabuk> createState() => _AnaKabukDurumu();
}

class _AnaKabukDurumu extends State<AnaKabuk> {
  int _seciliSekme = 0;

  /// Sekme gövdeleri bir kez oluşturulur ve `IndexedStack` hepsini widget
  /// ağacında tutar; yalnızca seçili olanı çizer. Bu yüzden sekme değişince
  /// ana sayfanın kaydırma konumu, arama kutusundaki yazı ve seçili kategori
  /// kaybolmaz. `body: _sekmeler[_seciliSekme]` yazılsaydı her geçişte ekran
  /// sıfırdan kurulur, listeler yeniden yüklenirdi.
  static const List<Widget> _sekmeler = [
    AnaEkran(),
    FavorilerEkrani(),
    SepetEkrani(),
    ProfilEkrani(),
  ];

  late final AuthProvider _oturum;

  /// En son işlenen oturum hâli. İlk çalıştırmada `null` olduğu için
  /// açılıştaki durum da bir "değişiklik" sayılıyor ve işleniyor.
  bool? _sonHal;

  @override
  void initState() {
    super.initState();

    // Kabuk artık misafire de açık. Kişiye bağlı iki veri — favoriler ve
    // sepet — oturum açılınca çekilmeli, kapanınca silinmeli. Bu yüzden
    // bir kez yüklemek yetmiyor, oturum dinleniyor.
    _oturum = context.read<AuthProvider>();
    _oturum.addListener(_oturumDegisti);

    // `initState` içinde doğrudan `notifyListeners` tetiklenemez; ilk
    // kare çizildikten sonra çalıştırılıyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _oturumDegisti();
    });
  }

  @override
  void dispose() {
    _oturum.removeListener(_oturumDegisti);
    super.dispose();
  }

  void _oturumDegisti() {
    final girisVar = _oturum.girisYapildi;

    // Sağlayıcı ad değişikliği gibi başka sebeplerle de haber veriyor;
    // yalnız giriş/çıkış geçişi ilgilendiriyor.
    if (girisVar == _sonHal) return;
    _sonHal = girisVar;

    final favoriler = context.read<FavoriProvider>();
    final sepet = context.read<SepetProvider>();

    if (girisVar) {
      // Kartlardaki kalpler ve sepet rozeti daha ilk karede doğru çizilsin
      // diye sekmeye girilmesi beklenmiyor.
      favoriler.yukle();
      sepet.yukle();
    } else {
      favoriler.temizle();
      sepet.temizle();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yalnız sayı dinleniyor; sepetin içeriği değişip adet aynı kalırsa
    // (örneğin başka bir ürünle değiştirilirse) kabuk yeniden çizilmez.
    final sepetAdedi = context.select<SepetProvider, int>(
      (saglayici) => saglayici.toplamAdet,
    );

    return Scaffold(
      body: IndexedStack(index: _seciliSekme, children: _sekmeler),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSekme,
        onDestinationSelected: (sira) => setState(() => _seciliSekme = sira),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Ürünler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
          NavigationDestination(
            icon: _SepetSimgesi(adet: sepetAdedi, dolu: false),
            selectedIcon: _SepetSimgesi(adet: sepetAdedi, dolu: true),
            label: 'Sepet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Sepet simgesi ve üstündeki adet rozeti.
///
/// Rozet yalnız sepette ürün varken görünür; sıfır yazan bir rozet bilgi
/// vermeden yer kaplardı.
class _SepetSimgesi extends StatelessWidget {
  final int adet;
  final bool dolu;

  const _SepetSimgesi({required this.adet, required this.dolu});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: adet > 0,
      label: Text('$adet'),
      child: Icon(dolu ? Icons.shopping_cart : Icons.shopping_cart_outlined),
    );
  }
}
