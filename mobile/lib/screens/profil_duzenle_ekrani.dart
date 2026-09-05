import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../core/dogrulayicilar.dart';
import '../models/kullanici.dart';
import '../providers/auth_provider.dart';

/// Kullanıcının kendi bilgilerini düzenlediği ekran.
///
/// İki bağımsız bölüm var: ad soyad güncelleme ve parola değiştirme. Ayrı
/// formlar ve ayrı düğmelerle çalışıyorlar; kullanıcı yalnızca adını
/// değiştirmek istediğinde parola alanlarını doldurmak zorunda kalmıyor.
class ProfilDuzenleEkrani extends StatelessWidget {
  final Kullanici kullanici;

  const ProfilDuzenleEkrani({super.key, required this.kullanici});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _EpostaBilgisi(eposta: kullanici.eposta),
          const SizedBox(height: 16),
          _AdSoyadBolumu(mevcutAd: kullanici.adSoyad),
          const SizedBox(height: 16),
          const _ParolaBolumu(),
        ],
      ),
    );
  }
}

/// E-postanın neden değiştirilemediğini açıklayan bilgi kartı.
class _EpostaBilgisi extends StatelessWidget {
  final String eposta;

  const _EpostaBilgisi({required this.eposta});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.mail_outline, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eposta,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'E-posta adresi değiştirilemez.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdSoyadBolumu extends StatefulWidget {
  final String mevcutAd;

  const _AdSoyadBolumu({required this.mevcutAd});

  @override
  State<_AdSoyadBolumu> createState() => _AdSoyadBolumuDurumu();
}

class _AdSoyadBolumuDurumu extends State<_AdSoyadBolumu> {
  final _formAnahtari = GlobalKey<FormState>();
  late final TextEditingController _ad;

  @override
  void initState() {
    super.initState();
    _ad = TextEditingController(text: widget.mevcutAd);
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final bildir = Bildirim(context);

    final hata =
        await context.read<AuthProvider>().profilGuncelle(_ad.text.trim());

    bildir.sonuc(hata, 'Adınız güncellendi.');
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = context.watch<AuthProvider>().islemSuruyor;

    return _Bolum(
      baslik: 'Ad Soyad',
      simge: Icons.person_outline,
      child: Form(
        key: _formAnahtari,
        child: Column(
          children: [
            TextFormField(
              controller: _ad,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              validator: Dogrulayicilar.adSoyad,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: islemSuruyor ? null : _kaydet,
              child: const Text('Adı Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParolaBolumu extends StatefulWidget {
  const _ParolaBolumu();

  @override
  State<_ParolaBolumu> createState() => _ParolaBolumuDurumu();
}

class _ParolaBolumuDurumu extends State<_ParolaBolumu> {
  final _formAnahtari = GlobalKey<FormState>();
  final _mevcut = TextEditingController();
  final _yeni = TextEditingController();
  final _yeniTekrar = TextEditingController();

  bool _gizli = true;

  @override
  void dispose() {
    _mevcut.dispose();
    _yeni.dispose();
    _yeniTekrar.dispose();
    super.dispose();
  }

  Future<void> _degistir() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final bildir = Bildirim(context);

    final hata = await context.read<AuthProvider>().parolaDegistir(
      mevcutParola: _mevcut.text,
      yeniParola: _yeni.text,
    );

    if (!mounted) return;

    if (hata != null) {
      bildir.hata(hata);
      return;
    }

    // Alanlar temizleniyor: parola ekranda takılı kalmasın.
    _mevcut.clear();
    _yeni.clear();
    _yeniTekrar.clear();

    bildir.basari('Parolanız değiştirildi.');
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = context.watch<AuthProvider>().islemSuruyor;

    return _Bolum(
      baslik: 'Parola Değiştir',
      simge: Icons.lock_outline,
      child: Form(
        key: _formAnahtari,
        child: Column(
          children: [
            TextFormField(
              controller: _mevcut,
              obscureText: _gizli,
              decoration: InputDecoration(
                labelText: 'Mevcut parola',
                suffixIcon: IconButton(
                  icon: Icon(
                    _gizli
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _gizli = !_gizli),
                ),
              ),
              validator: Dogrulayicilar.parola,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _yeni,
              obscureText: _gizli,
              decoration: const InputDecoration(
                labelText: 'Yeni parola',
                helperText: 'En az 8 karakter',
              ),
              validator: Dogrulayicilar.parola,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _yeniTekrar,
              obscureText: _gizli,
              decoration: const InputDecoration(
                labelText: 'Yeni parola (tekrar)',
              ),
              validator: (deger) =>
                  Dogrulayicilar.parolaTekrari(deger, _yeni.text),
            ),
            const SizedBox(height: 12),

            FilledButton(
              onPressed: islemSuruyor ? null : _degistir,
              child: const Text('Parolayı Değiştir'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Başlıklı kart kabuğu; iki bölüm de aynı düzeni kullanıyor.
class _Bolum extends StatelessWidget {
  final String baslik;
  final IconData simge;
  final Widget child;

  const _Bolum({
    required this.baslik,
    required this.simge,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  simge,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  baslik,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
