import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../core/dogrulayicilar.dart';
import '../models/kategori.dart';
import '../models/urun.dart';
import '../providers/urun_provider.dart';
import '../services/gorsel_service.dart';
import '../widgets/urun_gorseli.dart';

/// Yönetici için ürün ekleme ve düzenleme formu.
///
/// Tek ekran iki işi de yapıyor: [urun] boşsa yeni kayıt açılır, doluysa o
/// kayıt güncellenir. İki ayrı ekran yazılsaydı alanlar, doğrulayıcılar ve
/// görsel seçimi birebir tekrar ederdi; değişen tek şey hangi servis
/// metodunun çağrıldığı.
class UrunFormuEkrani extends StatefulWidget {
  final Urun? urun;

  const UrunFormuEkrani({super.key, this.urun});

  bool get duzenlemeMi => urun != null;

  @override
  State<UrunFormuEkrani> createState() => _UrunFormuEkraniDurumu();
}

class _UrunFormuEkraniDurumu extends State<UrunFormuEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _gorselServisi = GorselServisi();

  late final TextEditingController _ad;
  late final TextEditingController _aciklama;
  late final TextEditingController _fiyat;
  late final TextEditingController _stok;

  int? _kategoriId;

  /// Sunucudaki göreli adres (`/uploads/urun-...png`). Yeni görsel
  /// yüklenmediyse düzenlenen ürünün mevcut adresi burada durur.
  String? _gorselUrl;

  /// Seçilip henüz yüklenmemiş yerel dosya. Yalnızca önizleme için tutuluyor;
  /// yükleme bittiğinde adres [_gorselUrl] alanına yazılır.
  File? _yerelGorsel;

  bool _gorselYukleniyor = false;

  @override
  void initState() {
    super.initState();

    final urun = widget.urun;

    // Düzenleme kipinde alanlar mevcut değerlerle doluyor; ekleme kipinde boş.
    _ad = TextEditingController(text: urun?.ad ?? '');
    _aciklama = TextEditingController(text: urun?.aciklama ?? '');
    // Fiyat metin olarak tutuluyor: sunucu da metin bekliyor ve ondalık
    // basamak sayısı korunuyor.
    _fiyat = TextEditingController(
      text: urun == null ? '' : urun.fiyat.toStringAsFixed(2),
    );
    _stok = TextEditingController(text: urun?.stok.toString() ?? '');

    _kategoriId = urun?.kategoriId;
    _gorselUrl = urun?.gorselUrl;
  }

  @override
  void dispose() {
    _ad.dispose();
    _aciklama.dispose();
    _fiyat.dispose();
    _stok.dispose();
    super.dispose();
  }

  /// Galeriden görsel seçer ve hemen sunucuya yükler.
  ///
  /// Yükleme kaydetmeyi beklemiyor: kullanıcı görselin gerçekten gittiğini
  /// formu göndermeden görüyor. Karşılığında, kaydetmekten vazgeçilirse
  /// sunucuda sahipsiz bir dosya kalıyor — bu projede kabul edilen bir ödün.
  Future<void> _gorselSec() async {
    final secilen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Büyük fotoğraflar 2 MB sınırını aşmasın diye kaynakta küçültülüyor.
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (secilen == null || !mounted) return;

    final dosya = File(secilen.path);
    final bildir = Bildirim(context);

    // Sunucudaki multer sınırının aynısı istemcide de uygulanıyor: gereksiz
    // yere 2 MB'lık istek gönderilip reddedilmesin.
    if (await dosya.length() > GorselServisi.enFazlaBayt) {
      bildir.hata('Görsel en fazla 2 MB olabilir.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _yerelGorsel = dosya;
      _gorselYukleniyor = true;
    });

    try {
      final adres = await _gorselServisi.yukle(dosya.path);

      if (!mounted) return;

      setState(() {
        _gorselUrl = adres;
        _gorselYukleniyor = false;
      });
    } catch (hata) {
      if (!mounted) return;

      setState(() {
        _yerelGorsel = null;
        _gorselYukleniyor = false;
      });

      bildir.hata('Görsel yüklenemedi. Bağlantınızı kontrol edin.');
    }
  }

  void _gorseliKaldir() {
    setState(() {
      _yerelGorsel = null;
      _gorselUrl = null;
    });
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    if (_kategoriId == null) {
      Bildirim(context).hata('Kategori seçiniz.');
      return;
    }

    final saglayici = context.read<UrunProvider>();
    final yonlendirici = Navigator.of(context);
    final bildir = Bildirim(context);

    final urun = widget.urun;

    final hata = urun == null
        ? await saglayici.urunEkle(
            ad: _ad.text.trim(),
            aciklama: _aciklama.text.trim(),
            fiyat: _fiyat.text.trim(),
            stok: int.parse(_stok.text.trim()),
            kategoriId: _kategoriId!,
            gorselUrl: _gorselUrl,
          )
        : await saglayici.urunGuncelle(
            id: urun.id,
            ad: _ad.text.trim(),
            aciklama: _aciklama.text.trim(),
            fiyat: _fiyat.text.trim(),
            stok: int.parse(_stok.text.trim()),
            kategoriId: _kategoriId!,
            gorselUrl: _gorselUrl,
          );

    if (!mounted) return;

    if (hata != null) {
      bildir.hata(hata);
      return;
    }

    // Düzenlemede detay ekranındaki kayıt da bayatladığı için o ekran da
    // kapatılıyor; kullanıcı güncel listeye dönüyor.
    yonlendirici.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<UrunProvider>();
    final kaydediliyor = saglayici.yoneticiIslemi;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.duzenlemeMi ? 'Ürünü Düzenle' : 'Yeni Ürün'),
      ),
      body: Form(
        key: _formAnahtari,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GorselAlani(
              yerelGorsel: _yerelGorsel,
              gorselUrl: _gorselUrl,
              yukleniyor: _gorselYukleniyor,
              onSec: _gorselSec,
              onKaldir: _gorseliKaldir,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _ad,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ürün adı',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: Dogrulayicilar.urunAdi,
            ),
            const SizedBox(height: 14),

            _KategoriSecici(
              kategoriler: saglayici.kategoriler,
              secili: _kategoriId,
              onDegisti: (id) => setState(() => _kategoriId = id),
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fiyat,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Fiyat',
                      hintText: '0.00',
                      suffixText: 'TL',
                    ),
                    validator: Dogrulayicilar.fiyat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stok,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Stok',
                      hintText: '0',
                    ),
                    validator: Dogrulayicilar.stok,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _aciklama,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                alignLabelWithHint: true,
              ),
              validator: Dogrulayicilar.urunAciklamasi,
            ),
            const SizedBox(height: 10),

            FilledButton.icon(
              // Görsel yüklenirken kaydetmek, adresi henüz belli olmayan bir
              // ürünü kaydetmek olurdu.
              onPressed: (kaydediliyor || _gorselYukleniyor) ? null : _kaydet,
              icon: kaydediliyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(widget.duzenlemeMi ? 'Değişiklikleri Kaydet' : 'Ürünü Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görsel önizleme, seçme ve kaldırma bölümü.
class _GorselAlani extends StatelessWidget {
  final File? yerelGorsel;
  final String? gorselUrl;
  final bool yukleniyor;
  final VoidCallback onSec;
  final VoidCallback onKaldir;

  const _GorselAlani({
    required this.yerelGorsel,
    required this.gorselUrl,
    required this.yukleniyor,
    required this.onSec,
    required this.onKaldir,
  });

  @override
  Widget build(BuildContext context) {
    final varMi = yerelGorsel != null || gorselUrl != null;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Yeni seçilen dosya varsa doğrudan diskten gösteriliyor:
                // yükleme bitmeden de önizleme görünsün.
                if (yerelGorsel != null)
                  Image.file(yerelGorsel!, fit: BoxFit.cover)
                else
                  UrunGorseli(adres: gorselUrl, simgeBoyutu: 48),

                if (yukleniyor)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: yukleniyor ? null : onSec,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(varMi ? 'Görseli Değiştir' : 'Görsel Seç'),
              ),
            ),
            if (varMi) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Görseli kaldır',
                onPressed: yukleniyor ? null : onKaldir,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),

        Text(
          'PNG, JPEG veya WebP · en fazla 2 MB',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// Kategori açılır listesi.
///
/// Kategoriler zaten ürün sağlayıcısında duruyor; form ayrıca istek atmıyor.
class _KategoriSecici extends StatelessWidget {
  final List<Kategori> kategoriler;
  final int? secili;
  final ValueChanged<int?> onDegisti;

  const _KategoriSecici({
    required this.kategoriler,
    required this.secili,
    required this.onDegisti,
  });

  @override
  Widget build(BuildContext context) {
    if (kategoriler.isEmpty) {
      return const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Kategori',
          hintText: 'Kategoriler yüklenemedi',
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: secili,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: [
        for (final kategori in kategoriler)
          DropdownMenuItem(value: kategori.id, child: Text(kategori.ad)),
      ],
      onChanged: onDegisti,
      validator: (deger) => deger == null ? 'Kategori seçiniz.' : null,
    );
  }
}
