import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favori_provider.dart';
import '../providers/sepet_provider.dart';
import 'ana_ekran.dart';
import 'favoriler_ekrani.dart';
import 'profil_ekrani.dart';
import 'sepet_ekrani.dart';

/// Giriş yapıldıktan sonra açılan dört sekmeli kabuk.
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

  @override
  void initState() {
    super.initState();

    // Kartlardaki kalpler ve sepet rozeti ilk karede doğru çizilsin diye
    // ikisi de kabuk açılırken bir kez çekiliyor. Sekmeye girilmesi
    // beklenmiyor; rozet en baştan doğru sayıyı göstermeli.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<FavoriProvider>().yukle();
      context.read<SepetProvider>().yukle();
    });
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
