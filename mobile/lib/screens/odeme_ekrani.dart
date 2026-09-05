import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../core/theme/app_theme.dart';
import '../core/dogrulayicilar.dart';
import '../core/kart_bicimlendiriciler.dart';
import '../providers/sepet_provider.dart';
import '../providers/urun_provider.dart';
import 'siparis_basarili_ekrani.dart';

/// Teslimat adresi ve ödeme bilgisinin girildiği ekran.
///
/// **Bu bir ödeme simülasyonudur.** Gerçek bir kurulumda kart bilgisi ne bu
/// ekranda ne de kendi sunucumuzda dururdu: uygulama kartı doğrudan ödeme
/// kuruluşuna gönderir, sunucuya yalnızca bir jeton iletilirdi. Burada ödeme
/// kuruluşu olmadığı için akış taklit ediliyor.
///
/// Bu yüzden kart alanları **hiçbir yere kaydedilmiyor**: ekran kapanınca
/// denetleyicilerle birlikte bellekten siliniyor, sunucu da yalnızca son dört
/// haneyi ve karttaki adı saklıyor.
class OdemeEkrani extends StatefulWidget {
  const OdemeEkrani({super.key});

  @override
  State<OdemeEkrani> createState() => _OdemeEkraniDurumu();
}

class _OdemeEkraniDurumu extends State<OdemeEkrani> {
  final _formAnahtari = GlobalKey<FormState>();

  final _adres = TextEditingController();
  final _kartNumarasi = TextEditingController();
  final _sonKullanma = TextEditingController();
  final _cvv = TextEditingController();
  final _kartSahibi = TextEditingController();

  @override
  void dispose() {
    _adres.dispose();
    _kartNumarasi.dispose();
    _sonKullanma.dispose();
    _cvv.dispose();
    _kartSahibi.dispose();
    super.dispose();
  }

  Future<void> _odemeyiTamamla() async {
    // Önce istemcideki kurallar; sunucuya gitmeden hatalar gösterilir.
    if (!_formAnahtari.currentState!.validate()) return;

    final saglayici = context.read<SepetProvider>();
    final urunler = context.read<UrunProvider>();

    final sonuc = await saglayici.siparisVer(
      adres: _adres.text.trim(),
      kartNumarasi: _kartNumarasi.text,
      sonKullanma: _sonKullanma.text.trim(),
      cvv: _cvv.text.trim(),
      kartSahibi: _kartSahibi.text.trim(),
    );

    if (!mounted) return;

    if (!sonuc.basarili) {
      Bildirim(context).hata(sonuc.hata!);
      return;
    }

    // Sipariş verilince stok düştü; listedeki "son 2 adet" gibi bilgiler
    // yanlış kalmasın diye ürünler yeniden çekiliyor.
    urunler.yenidenYukle();

    // Ödeme ekranı geçmişten çıkarılıyor: kullanıcı başarı ekranından geri
    // tuşuna bastığında doldurulmuş bir ödeme formuna dönmemeli.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SiparisBasariliEkrani(siparis: sonuc.siparis!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>().sepet;
    final veriliyor = context.select<SepetProvider, bool>(
      (saglayici) => saglayici.siparisVeriliyor,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme')),
      body: Form(
        key: _formAnahtari,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OzetKarti(
              urunSayisi: sepet.satirlar.length,
              toplamAdet: sepet.toplamAdet,
              toplamMetni: sepet.toplamMetni,
            ),
            const SizedBox(height: 20),

            const _BolumBasligi(simge: Icons.local_shipping_outlined, baslik: 'Teslimat Adresi'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _adres,
              maxLines: 3,
              maxLength: 500,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Mahalle, cadde, kapı no, ilçe/il',
              ),
              validator: Dogrulayicilar.adres,
            ),
            const SizedBox(height: 12),

            const _BolumBasligi(simge: Icons.credit_card, baslik: 'Kart Bilgileri'),
            const SizedBox(height: 10),

            TextFormField(
              controller: _kartSahibi,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Kart üzerindeki ad',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: Dogrulayicilar.kartSahibi,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _kartNumarasi,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                KartNumarasiBicimi(),
              ],
              decoration: const InputDecoration(
                labelText: 'Kart numarası',
                hintText: '0000 0000 0000 0000',
                prefixIcon: Icon(Icons.credit_card),
                counterText: '',
              ),
              validator: Dogrulayicilar.kartNumarasi,
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sonKullanma,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      SonKullanmaBicimi(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Son kullanma',
                      hintText: 'AA/YY',
                    ),
                    validator: Dogrulayicilar.sonKullanma,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    keyboardType: TextInputType.number,
                    // Omuz üstünden okunmasın diye gizleniyor.
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '000',
                    ),
                    validator: Dogrulayicilar.cvv,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const _SimulasyonUyarisi(),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: veriliyor ? null : _odemeyiTamamla,
              icon: veriliyor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                veriliyor ? 'İşleniyor...' : '${sepet.toplamMetni} Öde',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OzetKarti extends StatelessWidget {
  final int urunSayisi;
  final int toplamAdet;
  final String toplamMetni;

  const _OzetKarti({
    required this.urunSayisi,
    required this.toplamAdet,
    required this.toplamMetni,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sipariş Özeti',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$urunSayisi üründe $toplamAdet adet',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Spacer(),
            Text(
              toplamMetni,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: UygulamaTemasi.vurgu,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  final IconData simge;
  final String baslik;

  const _BolumBasligi({required this.simge, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(simge, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          baslik,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SimulasyonUyarisi extends StatelessWidget {
  const _SimulasyonUyarisi();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu bir ödeme simülasyonudur. Gerçek tahsilat yapılmaz; '
              'kart numaranızın yalnızca son dört hanesi kaydedilir.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
