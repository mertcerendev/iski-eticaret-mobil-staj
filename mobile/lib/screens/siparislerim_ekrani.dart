import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/siparis.dart';
import '../providers/siparis_provider.dart';
import '../widgets/durum_gorunumleri.dart';
import '../widgets/siparis_durum_rozeti.dart';
import 'siparis_detay_ekrani.dart';

/// Kullanıcının geçmiş siparişleri.
///
/// Profil sekmesinden açılıyor; alt gezinmede kendi sekmesi yok çünkü
/// dört sekme zaten dolu ve sipariş geçmişi günlük kullanılan bir bölüm değil.
class SiparislerimEkrani extends StatefulWidget {
  const SiparislerimEkrani({super.key});

  @override
  State<SiparislerimEkrani> createState() => _SiparislerimEkraniDurumu();
}

class _SiparislerimEkraniDurumu extends State<SiparislerimEkrani> {
  @override
  void initState() {
    super.initState();

    // Ekran açılır açılmaz liste çekiliyor. `initState` içinde doğrudan
    // istek atılamaz: ilk çizim bitmeden `notifyListeners()` çağrılırsa
    // Flutter hata verir. Bu yüzden ilk kareden sonraya bırakılıyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<SiparisProvider>().yukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<SiparisProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: _icerik(saglayici),
    );
  }

  Widget _icerik(SiparisProvider saglayici) {
    // Elde liste varken yeniden yükleme çalışırsa tam ekran göstergeye
    // dönülmüyor; kullanıcı mevcut listeyi kaybetmiyor.
    if (saglayici.yukleniyor && saglayici.bosMu) {
      return const YukleniyorGorunumu();
    }

    if (saglayici.hata != null && saglayici.bosMu) {
      return HataGorunumu(mesaj: saglayici.hata!, onTekrarDene: saglayici.yukle);
    }

    if (saglayici.bosMu) {
      return const BosGorunumu(
        baslik: 'Henüz siparişiniz yok',
        aciklama:
            'Sepetinizi tamamladığınızda siparişleriniz burada listelenecek.',
      );
    }

    return RefreshIndicator(
      onRefresh: saglayici.yukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: saglayici.siparisler.length,
        itemBuilder: (context, sira) {
          return _SiparisKarti(siparis: saglayici.siparisler[sira]);
        },
      ),
    );
  }
}

class _SiparisKarti extends StatelessWidget {
  final Siparis siparis;

  const _SiparisKarti({required this.siparis});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SiparisDetayEkrani(siparisId: siparis.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    siparis.numara,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  SiparisDurumRozeti(durum: siparis.durum),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                siparis.tarihMetni,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),

              // Kalem adları tek satırda özetleniyor; kaç kalem olduğunu
              // saymak yerine kullanıcı ne aldığını doğrudan görüyor.
              Text(
                siparis.kalemler.map((kalem) => kalem.urunAd).join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    '${siparis.kalemler.length} üründe '
                    '${siparis.toplamAdet} adet',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Text(
                    siparis.toplamMetni,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: UygulamaTemasi.vurgu,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
