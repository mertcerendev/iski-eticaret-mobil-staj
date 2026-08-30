import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favori_provider.dart';
import '../providers/urun_provider.dart';
import '../services/urun_service.dart';
import '../widgets/durum_gorunumleri.dart';
import '../widgets/urun_karti.dart';
import 'favoriler_ekrani.dart';
import 'urun_detay_ekrani.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkraniDurumu();
}

class _AnaEkraniDurumu extends State<AnaEkran> {
  final _kaydirmaDenetleyici = ScrollController();
  final _aramaDenetleyici = TextEditingController();

  /// Liste sonuna bu kadar piksel kala sonraki sayfa istenir. Kullanıcı
  /// sona varmadan yükleme başlasın ki bekleme hissedilmesin.
  static const double _yuklemeEsigi = 400;

  @override
  void initState() {
    super.initState();

    _kaydirmaDenetleyici.addListener(_kaydirmayiDinle);

    // `initState` içinde doğrudan istek atılamaz; ilk çizim bitmeden
    // `notifyListeners()` çağrılırsa Flutter hata verir. Bu yüzden ilk
    // kareden sonraya bırakılır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<UrunProvider>().baslat();

      // Kartlardaki kalbin dolu mu boş mu çizileceği bu listeye bakılarak
      // belirlenir; ürün ucu favori bilgisi döndürmediği için bir kez
      // ayrıca çekilir.
      context.read<FavoriProvider>().yukle();
    });
  }

  @override
  void dispose() {
    _kaydirmaDenetleyici.dispose();
    _aramaDenetleyici.dispose();
    super.dispose();
  }

  void _kaydirmayiDinle() {
    final konum = _kaydirmaDenetleyici.position;

    if (konum.pixels >= konum.maxScrollExtent - _yuklemeEsigi) {
      context.read<UrunProvider>().dahaFazlaYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          IconButton(
            tooltip: 'Favorilerim',
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavorilerEkrani()),
            ),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: _cikisOnayi,
          ),
        ],
      ),
      body: Column(
        children: [
          const _KullaniciSeridi(),
          _AramaKutusu(denetleyici: _aramaDenetleyici),
          const _KategoriCipleri(),
          const _SonucSatiri(),
          Expanded(child: _icerik()),
        ],
      ),
    );
  }

  Widget _icerik() {
    final saglayici = context.watch<UrunProvider>();

    if (saglayici.ilkYuklemeSuruyor) {
      return const YukleniyorGorunumu();
    }

    if (saglayici.hata != null) {
      return HataGorunumu(
        mesaj: saglayici.hata!,
        onTekrarDene: saglayici.yenidenYukle,
      );
    }

    if (saglayici.bosMu) {
      return BosGorunumu(
        baslik: 'Ürün bulunamadı',
        aciklama: saglayici.suzgecUygulandi
            ? 'Arama ve filtrelerinizi değiştirmeyi deneyin.'
            : 'Henüz ürün eklenmemiş.',
        butonMetni: saglayici.suzgecUygulandi ? 'Filtreleri temizle' : null,
        onButon: () {
          _aramaDenetleyici.clear();
          saglayici.suzgecleriTemizle();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: saglayici.yenidenYukle,
      child: CustomScrollView(
        controller: _kaydirmaDenetleyici,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, sira) {
                  final urun = saglayici.urunler[sira];

                  return UrunKarti(
                    urun: urun,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UrunDetayEkrani(urun: urun),
                      ),
                    ),
                  );
                },
                childCount: saglayici.urunler.length,
              ),
            ),
          ),

          // Sonraki sayfa yüklenirken listenin altında dönen halka.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: saglayici.dahaYukleniyor
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : saglayici.dahaVarMi
                        ? const SizedBox.shrink()
                        : Text(
                            'Tüm ürünler gösterildi',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cikisOnayi() async {
    final saglayici = context.read<AuthProvider>();

    final onay = await showDialog<bool>(
      context: context,
      builder: (pencere) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Oturumunuz kapatılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(pencere).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(pencere).pop(true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (onay == true) {
      await saglayici.cikisYap();
    }
  }
}

/// Giriş yapan kullanıcıyı ve yönetici rozetini gösteren şerit.
class _KullaniciSeridi extends StatelessWidget {
  const _KullaniciSeridi();

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<AuthProvider>();
    final kullanici = saglayici.kullanici;

    if (kullanici == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hoş geldiniz, ${kullanici.adSoyad}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          if (saglayici.yoneticiMi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'YÖNETİCİ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AramaKutusu extends StatelessWidget {
  final TextEditingController denetleyici;

  const _AramaKutusu({required this.denetleyici});

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<UrunProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: denetleyici,
        textInputAction: TextInputAction.search,

        // Her tuşta çağrılır ama istek hemen atılmaz; sağlayıcı içindeki
        // sayaç yarım saniye bekler (debounce).
        onChanged: saglayici.aramaDegisti,

        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: saglayici.arama.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    denetleyici.clear();
                    saglayici.aramaDegisti('');
                  },
                ),
          isDense: true,
        ),
      ),
    );
  }
}

/// Kategori filtresi ve sıralama menüsü.
class _KategoriCipleri extends StatelessWidget {
  const _KategoriCipleri();

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<UrunProvider>();

    if (saglayici.kategoriler.isEmpty) return const SizedBox(height: 8);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // "Tümü" seçeneği ayrı bir kategori değil, filtrenin kaldırılması.
          FilterChip(
            label: const Text('Tümü'),
            selected: saglayici.seciliKategoriId == null,
            onSelected: (_) => saglayici.kategoriSec(null),
          ),
          const SizedBox(width: 8),

          for (final kategori in saglayici.kategoriler) ...[
            FilterChip(
              label: Text(kategori.ad),
              selected: saglayici.seciliKategoriId == kategori.id,
              onSelected: (secildi) =>
                  saglayici.kategoriSec(secildi ? kategori.id : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Kaç sonuç bulunduğunu ve sıralama seçeneğini gösteren satır.
class _SonucSatiri extends StatelessWidget {
  const _SonucSatiri();

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<UrunProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              saglayici.ilkYuklemeSuruyor
                  ? ''
                  : '${saglayici.toplam} ürün bulundu',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          PopupMenuButton<Siralama>(
            initialValue: saglayici.siralama,
            onSelected: saglayici.siralamaSec,
            itemBuilder: (_) => [
              for (final secenek in Siralama.values)
                PopupMenuItem(value: secenek, child: Text(secenek.etiket)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    saglayici.siralama.etiket,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
