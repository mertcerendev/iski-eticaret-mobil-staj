import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kullanici.dart';
import '../providers/auth_provider.dart';
import '../providers/favori_provider.dart';
import '../providers/sepet_provider.dart';
import '../widgets/durum_gorunumleri.dart';
import 'profil_duzenle_ekrani.dart';
import 'siparislerim_ekrani.dart';
import 'yonetici_siparisler_ekrani.dart';

/// Giriş yapan kullanıcının bilgileri ve çıkış düğmesi.
///
/// Çıkış Gün 10'a kadar ana sayfanın başlık çubuğundaydı. Alt gezinme
/// gelince profil sekmesi açıldı ve çıkış oraya taşındı; hesapla ilgili
/// işler tek yerde toplanıyor.
class ProfilEkrani extends StatelessWidget {
  const ProfilEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final kullanici = context.watch<AuthProvider>().kullanici;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          if (kullanici != null)
            IconButton(
              tooltip: 'Profili düzenle',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilDuzenleEkrani(kullanici: kullanici),
                ),
              ),
            ),
        ],
      ),
      body: kullanici == null
          ? const YukleniyorGorunumu()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _KimlikKarti(kullanici: kullanici),
                const SizedBox(height: 16),
                const _SayilarSatiri(),
                const SizedBox(height: 16),

                // Sipariş geçmişi alt gezinmede kendi sekmesini almadı:
                // dört sekme dolu ve geçmiş günlük kullanılan bir bölüm değil.
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Siparişlerim'),
                    subtitle: const Text('Geçmiş siparişleriniz ve durumları'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SiparislerimEkrani(),
                      ),
                    ),
                  ),
                ),

                // Yönetici bölümü yalnızca rolü uygun olana çiziliyor.
                if (kullanici.yoneticiMi) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Sipariş Yönetimi'),
                      subtitle: const Text(
                        'Tüm siparişleri görüntüle ve durumlarını güncelle',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const YoneticiSiparislerEkrani(),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () => _cikisOnayi(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Çıkış Yap'),
                ),
              ],
            ),
    );
  }

  Future<void> _cikisOnayi(BuildContext context) async {
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

class _KimlikKarti extends StatelessWidget {
  final Kullanici kullanici;

  const _KimlikKarti({required this.kullanici});

  /// Ad ve soyadın ilk harfleri. Kullanıcının yüklediği bir fotoğraf
  /// olmadığı için baş harfler yer tutucu olarak kullanılıyor.
  String get _basHarfler {
    final parcalar = kullanici.adSoyad.trim().split(RegExp(r'\s+'));

    if (parcalar.length == 1) return parcalar.first.characters.first;

    return '${parcalar.first.characters.first}${parcalar.last.characters.first}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Text(
                _basHarfler.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tema.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              kullanici.adSoyad,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            Text(
              kullanici.eposta,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            if (kullanici.yoneticiMi) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'YÖNETİCİ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Favori ve sepet sayıları. İkisi de sağlayıcılarda zaten duruyor;
/// burada ayrıca istek atılmıyor.
class _SayilarSatiri extends StatelessWidget {
  const _SayilarSatiri();

  @override
  Widget build(BuildContext context) {
    final favoriAdedi = context.select<FavoriProvider, int>((s) => s.adet);
    final sepetAdedi = context.select<SepetProvider, int>((s) => s.toplamAdet);

    return Row(
      children: [
        Expanded(
          child: _SayiKutusu(
            simge: Icons.favorite,
            baslik: 'Favori',
            deger: '$favoriAdedi',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SayiKutusu(
            simge: Icons.shopping_cart,
            baslik: 'Sepetteki adet',
            deger: '$sepetAdedi',
          ),
        ),
      ],
    );
  }
}

class _SayiKutusu extends StatelessWidget {
  final IconData simge;
  final String baslik;
  final String deger;

  const _SayiKutusu({
    required this.simge,
    required this.baslik,
    required this.deger,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(simge, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              deger,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              baslik,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
