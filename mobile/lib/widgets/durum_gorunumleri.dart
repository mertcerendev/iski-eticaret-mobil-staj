import 'package:flutter/material.dart';

/// Liste ekranlarının üç özel hâli: yükleniyor, boş sonuç, hata.
///
/// Bu üçü ayrı ayrı ele alınmazsa kullanıcı boş bir ekranla karşılaşır ve
/// uygulamanın çalışıp çalışmadığını anlayamaz.

class YukleniyorGorunumu extends StatelessWidget {
  const YukleniyorGorunumu({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class BosGorunumu extends StatelessWidget {
  final String baslik;
  final String? aciklama;
  final String? butonMetni;
  final VoidCallback? onButon;

  const BosGorunumu({
    super.key,
    required this.baslik,
    this.aciklama,
    this.butonMetni,
    this.onButon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (aciklama != null) ...[
              const SizedBox(height: 8),
              Text(
                aciklama!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (butonMetni != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onButon, child: Text(butonMetni!)),
            ],
          ],
        ),
      ),
    );
  }
}

class HataGorunumu extends StatelessWidget {
  final String mesaj;
  final VoidCallback onTekrarDene;

  const HataGorunumu({
    super.key,
    required this.mesaj,
    required this.onTekrarDene,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bir sorun oluştu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onTekrarDene,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
