import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/kategori.dart';
import '../models/urun.dart';
import '../providers/auth_provider.dart';
import '../providers/urun_provider.dart';
import '../services/urun_service.dart';
import '../widgets/durum_gorunumleri.dart';
import '../widgets/iskelet.dart';
import '../widgets/urun_karti.dart';
import 'urun_detay_ekrani.dart';
import 'urun_formu_ekrani.dart';

/// Uygulamanın ana ekranı.
///
/// İki farklı kipte çalışıyor:
///
/// - **Keşif kipi** (arama ve süzgeç boşken): karşılama şeridi, kategori
///   simgeleri, iki yatay ürün şeridi ve altında tüm ürünler ızgarası.
/// - **Arama kipi** (arama yazıldığında ya da süzgeç seçildiğinde): keşif
///   bölümleri gizlenip ekran tamamen sonuçlara ayrılıyor.
///
/// Ayrım bilinçli: kullanıcı bir şey ararken keşif içeriği sonuçları aşağı
/// itip aramayı zorlaştırırdı.
/// Yatay şeritteki kartın genişliği. Kare görselin kenarı da bu ölçüde.
/// Hem şeridi hem kart genişliğini besliyor; iki yerde ayrı yazılsaydı
/// biri değişince şerit yüksekliği kartla uyumsuz kalırdı.
const double _seritKartGenisligi = 150;

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkraniDurumu();
}

class _AnaEkraniDurumu extends State<AnaEkran> {
  final _kaydirmaDenetleyici = ScrollController();
  final _aramaDenetleyici = TextEditingController();

  /// Hero etiketlerinin bu sekmeye ait olduğunu belirtir; favoriler sekmesi
  /// aynı anda ağaçta olduğu için etiketler ayrışmak zorunda.
  static const String _heroOneki = 'liste';

  /// Liste sonuna bu kadar piksel kala sonraki sayfa istenir.
  static const double _yuklemeEsigi = 400;


  @override
  void initState() {
    super.initState();

    _kaydirmaDenetleyici.addListener(_kaydirmayiDinle);

    // `initState` içinde doğrudan istek atılamaz; ilk çizim bitmeden
    // `notifyListeners()` çağrılırsa Flutter hata verir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<UrunProvider>().baslat();
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

  /// Detay ekranını açar.
  ///
  /// [onek] parametresi şart: aynı ürün hem ızgarada hem keşif şeritlerinde
  /// bulunabiliyor ve her biri farklı Hero etiketi taşıyor. Detay ekranına
  /// hangi karttan gelindiyse o önek geçirilmezse etiketler tutmaz ve geçiş
  /// animasyonu hiç oynamaz.
  void _urunAc(Urun urun, String onek) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UrunDetayEkrani(urun: urun, heroOneki: onek),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<UrunProvider>();

    // Ekleme düğmesi yalnızca yöneticiye gösteriliyor. Bu bir görünüm
    // kolaylığı; asıl yetki denetimi sunucudaki `requireAdmin` katmanında.
    final yoneticiMi = context.watch<AuthProvider>().yoneticiMi;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuvia')),
      floatingActionButton: yoneticiMi
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UrunFormuEkrani()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Ürün'),
            )
          : null,
      body: RefreshIndicator(
        // Şeritler de yenileniyor: kullanıcının aşağı çekmesi "ekrandaki
        // her şeyi tazele" demek.
        onRefresh: saglayici.tazele,
        child: CustomScrollView(
          controller: _kaydirmaDenetleyici,
          slivers: [
            SliverToBoxAdapter(
              child: _AramaKutusu(denetleyici: _aramaDenetleyici),
            ),

            if (saglayici.kesifGosterilsin)
              const SliverToBoxAdapter(child: _Afis()),

            // Kategori şeridi her iki kipte de duruyor.
            //
            // Önceden yalnızca keşif kipindeydi; bir kategoriye dokunulunca
            // ekran arama kipine geçtiği için şerit kaybolup yerine düz
            // yazılı çipler geliyordu. Kullanıcının seçim yaptığı anda
            // dokunduğu yerin biçim değiştirmesi, üstelik komşu kategorilere
            // geçmek için ikinci bir arayüzü öğrenmek zorunda kalması kötü
            // bir davranıştı. Artık şerit yerinde kalıyor, seçili kategori
            // üzerinde işaretleniyor.
            SliverToBoxAdapter(
              child: _KategoriSeridi(
                kategoriler: saglayici.kategoriler,
                seciliId: saglayici.seciliKategoriId,
                onSecildi: saglayici.kategoriSec,
              ),
            ),

            // ── Keşif şeritleri ───────────────────────────────────
            // Bunlar gizleniyor: kullanıcı arama ya da süzgeç uyguladığında
            // ekran sonuçlara ayrılmalı, keşif içeriği sonuçları aşağı
            // itmemeli.
            if (saglayici.kesifGosterilsin) ...[
              SliverToBoxAdapter(
                child: _UrunSeridi(
                  baslik: 'Yeni Gelenler',
                  simge: Icons.new_releases_outlined,
                  urunler: saglayici.yeniUrunler,
                  heroOneki: '$_heroOneki-yeni',
                  onUrun: (urun) => _urunAc(urun, '$_heroOneki-yeni'),
                ),
              ),
              SliverToBoxAdapter(
                child: _UrunSeridi(
                  baslik: 'Uygun Fiyatlılar',
                  simge: Icons.local_offer_outlined,
                  urunler: saglayici.uygunUrunler,
                  heroOneki: '$_heroOneki-uygun',
                  onUrun: (urun) => _urunAc(urun, '$_heroOneki-uygun'),
                ),
              ),
            ],

            SliverToBoxAdapter(
              child: _BolumBasligi(saglayici: saglayici),
            ),

            ..._icerikSliverlari(saglayici),
          ],
        ),
      ),
    );
  }

  List<Widget> _icerikSliverlari(UrunProvider saglayici) {
    if (saglayici.ilkYuklemeSuruyor) {
      return const [SliverToBoxAdapter(child: IzgaraIskeleti())];
    }

    if (saglayici.hata != null) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: HataGorunumu(
              mesaj: saglayici.hata!,
              onTekrarDene: saglayici.yenidenYukle,
            ),
          ),
        ),
      ];
    }

    if (saglayici.bosMu) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 320,
            child: BosGorunumu(
              baslik: 'Ürün bulunamadı',
              aciklama: saglayici.suzgecUygulandi
                  ? 'Arama ve filtrelerinizi değiştirmeyi deneyin.'
                  : 'Henüz ürün eklenmemiş.',
              butonMetni:
                  saglayici.suzgecUygulandi ? 'Filtreleri temizle' : null,
              onButon: () {
                _aramaDenetleyici.clear();
                saglayici.suzgecleriTemizle();
              },
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // Kart yüksekliği = genişlik / oran. Ekran 411 dp genişliğinde,
            // kart ≈ 187 dp; görsel 187 + metin 119 = 306 → oran ≈ 0.61.
            childAspectRatio: 0.61,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, sira) {
              final urun = saglayici.urunler[sira];

              return UrunKarti(
                urun: urun,
                heroOneki: _heroOneki,
                onTap: () => _urunAc(urun, _heroOneki),
              );
            },
            childCount: saglayici.urunler.length,
          ),
        ),
      ),

      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
    ];
  }
}

/// Arama kutusu.
class _AramaKutusu extends StatelessWidget {
  final TextEditingController denetleyici;

  const _AramaKutusu({required this.denetleyici});

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<UrunProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: denetleyici,
        textInputAction: TextInputAction.search,

        // Her tuşta çağrılır ama istek hemen atılmaz; sağlayıcı içindeki
        // sayaç yarım saniye bekler (debounce).
        onChanged: saglayici.aramaDegisti,

        decoration: InputDecoration(
          // Sunucu yalnızca ürün ADINDA arıyor (`name contains`). İpucu
          // "kategori veya marka" deseydi kullanıcı kategori adı yazıp boş
          // sonuç alır ve aramanın bozuk olduğunu düşünürdü. Kategoriye göre
          // süzme için altındaki çipler var.
          hintText: 'Ürün adında ara',
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

/// Karşılama afişi.
///
/// Kampanya ya da indirim yazmıyor: sunucuda böyle bir veri yok, uydurulmuş
/// bir kampanya sunumda savunulamazdı. Afiş marka kimliğini taşıyor.
class _Afis extends StatelessWidget {
  const _Afis();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          // Görsel bu oranda kırpılmış hâlde geliyor; kutu da aynı oranda
          // veriliyor ki `cover` ile kenarlardan bir şey kesilmesin.
          aspectRatio: 2.4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/marka/afis.jpg', fit: BoxFit.cover),

              // Görselin solu koyu ama düz değil, üstünde parıltılar var.
              // Yazının her cihazda okunabilmesi için sol taraf ayrıca
              // karartılıyor; sağdaki ürünler açıkta kalıyor.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.62],
                    colors: [
                      UygulamaTemasi.lacivert.withValues(alpha: 0.88),
                      UygulamaTemasi.lacivert.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.55,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nuvia’ya hoş geldiniz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Beş kategoride seçili ürünler',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kategori simgeleri şeridi.
///
/// Başındaki "Tümü" girişi seçimi kaldırıyor; süzgeci temizlemek için ayrı
/// bir düğme aramaya gerek kalmıyor.
class _KategoriSeridi extends StatelessWidget {
  final List<Kategori> kategoriler;
  final int? seciliId;
  final ValueChanged<int?> onSecildi;

  const _KategoriSeridi({
    required this.kategoriler,
    required this.seciliId,
    required this.onSecildi,
  });

  /// Kategori adına göre simge. Sunucuda simge alanı yok; eşleme burada
  /// yapılıyor, tanınmayan kategori genel bir simge alıyor.
  static IconData _simge(String ad) {
    switch (ad.toLowerCase()) {
      case 'elektronik':
        return Icons.devices_other;
      case 'ev aletleri':
        return Icons.kitchen_outlined;
      case 'giyim':
        return Icons.checkroom;
      case 'kitap':
        return Icons.menu_book_outlined;
      case 'oyuncak':
        return Icons.toys_outlined;
      case 'spor':
        return Icons.fitness_center;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kategoriler.isEmpty) return const SizedBox(height: 8);

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),

        // Bir fazlası baştaki "Tümü" girişi.
        itemCount: kategoriler.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, sira) {
          if (sira == 0) {
            return _KategoriDugmesi(
              ad: 'Tümü',
              simge: Icons.apps,
              secili: seciliId == null,
              onTap: () => onSecildi(null),
            );
          }

          final kategori = kategoriler[sira - 1];

          return _KategoriDugmesi(
            ad: kategori.ad,
            simge: _simge(kategori.ad),
            secili: seciliId == kategori.id,
            onTap: () => onSecildi(kategori.id),
          );
        },
      ),
    );
  }
}

/// Şeritteki tek kategori: yuvarlak simge ve altında adı.
class _KategoriDugmesi extends StatelessWidget {
  final String ad;
  final IconData simge;
  final bool secili;
  final VoidCallback onTap;

  const _KategoriDugmesi({
    required this.ad,
    required this.simge,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // Seçili olan koyu marka moruyla doluyor, diğerleri soluk mor kalıyor.
    // Yalnız yazıyı kalınlaştırmak yetmiyordu: göz önce daireleri tarıyor,
    // hangisinin seçili olduğu bir bakışta anlaşılmalı.
    //
    // Turuncu kullanılmadı: o renk fiyat ve stok uyarısına ayrıldı. Seçili
    // kategori de turuncu olsaydı renk tek bir şey anlatmaz olurdu.
    final zemin =
        secili ? tema.colorScheme.primary : tema.colorScheme.primaryContainer;
    final onZemin =
        secili ? tema.colorScheme.onPrimary : tema.colorScheme.onPrimaryContainer;

    return SizedBox(
      width: 66,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: zemin, shape: BoxShape.circle),
              child: Icon(simge, color: onZemin, size: 25),
            ),
            const SizedBox(height: 6),
            Text(
              ad,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: secili ? FontWeight.w700 : FontWeight.normal,
                color: secili ? tema.colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Başlıklı yatay ürün şeridi.
class _UrunSeridi extends StatelessWidget {
  final String baslik;
  final IconData simge;
  final List<Urun> urunler;
  final String heroOneki;
  final ValueChanged<Urun> onUrun;

  const _UrunSeridi({
    required this.baslik,
    required this.simge,
    required this.urunler,
    required this.heroOneki,
    required this.onUrun,
  });

  @override
  Widget build(BuildContext context) {
    if (urunler.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(simge, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 7),
              Text(baslik, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        SizedBox(
          // Kare görsel (150) + kartın metin bölümü için gereken yükseklik.
          // Elle sayı vermek yerine karttan okunuyor: kart tasarımı
          // değişirse şerit de kendiliğinden uyum sağlıyor.
          height: _seritKartGenisligi + UrunKarti.metinYuksekligi,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: urunler.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, sira) {
              final urun = urunler[sira];

              return UrunKarti(
                urun: urun,
                heroOneki: heroOneki,
                genislik: _seritKartGenisligi,
                onTap: () => onUrun(urun),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Tüm Ürünler" başlığı, sonuç sayısı ve sıralama menüsü.
class _BolumBasligi extends StatelessWidget {
  final UrunProvider saglayici;

  const _BolumBasligi({required this.saglayici});

  @override
  Widget build(BuildContext context) {
    final aramaKipi = saglayici.suzgecUygulandi;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aramaKipi ? 'Sonuçlar' : 'Tüm Ürünler',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!saglayici.ilkYuklemeSuruyor)
                  Text(
                    '${saglayici.toplam} ürün',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
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
