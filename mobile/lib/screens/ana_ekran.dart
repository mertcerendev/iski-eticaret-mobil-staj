import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kategori.dart';
import '../models/urun.dart';
import '../providers/auth_provider.dart';
import '../widgets/urun_karti.dart';

// ─────────────────────────────────────────────────────────────
// GEÇİCİ VERİ — Gün 9'da bu blok silinecek, yerine
// API'den gelen gerçek ürünler kullanılacak.
// ─────────────────────────────────────────────────────────────
const _elektronik = Kategori(id: 1, ad: 'Elektronik', slug: 'elektronik');
const _evAletleri = Kategori(id: 2, ad: 'Ev Aletleri', slug: 'ev-aletleri');

const sahteUrunler = <Urun>[
  Urun(
    id: 1,
    ad: 'Kablosuz Kulaklık',
    aciklama: 'Aktif gürültü engelleme, 30 saat pil ömrü.',
    fiyat: 1499.90,
    stok: 25,
    kategoriId: 1,
    kategori: _elektronik,
  ),
  Urun(
    id: 2,
    ad: 'Mekanik Klavye',
    aciklama: 'Mavi switch, RGB aydınlatma, Türkçe Q düzen.',
    fiyat: 899.90,
    stok: 0,
    kategoriId: 1,
    kategori: _elektronik,
  ),
  Urun(
    id: 3,
    ad: 'Akıllı Saat',
    aciklama: 'Nabız ve uyku takibi, 7 gün pil ömrü.',
    fiyat: 2299.00,
    stok: 3,
    kategoriId: 1,
    kategori: _elektronik,
  ),
  Urun(
    id: 4,
    ad: 'Kahve Makinesi',
    aciklama: 'Otomatik öğütücülü espresso makinesi.',
    fiyat: 3499.00,
    stok: 7,
    kategoriId: 2,
    kategori: _evAletleri,
  ),
  Urun(
    id: 5,
    ad: 'Su Isıtıcısı',
    aciklama: '1.7 litre paslanmaz çelik, otomatik kapanma.',
    fiyat: 649.90,
    stok: 12,
    kategoriId: 2,
    kategori: _evAletleri,
  ),
];

class AnaEkran extends StatelessWidget {
  const AnaEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<AuthProvider>();
    final kullanici = saglayici.kullanici;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: () => _cikisOnayi(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (kullanici != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hoş geldiniz, ${kullanici.adSoyad}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (saglayici.yoneticiMi)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
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
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: sahteUrunler.length,
              itemBuilder: (context, sira) {
                return UrunKarti(urun: sahteUrunler[sira]);
              },
            ),
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
