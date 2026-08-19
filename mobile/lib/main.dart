import 'package:flutter/material.dart';
import 'models/urun.dart';
import 'widgets/urun_karti.dart';

void main() {
  runApp(const UygulamaKoku());
}

class UygulamaKoku extends StatelessWidget {
  const UygulamaKoku({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İSKİ E-Ticaret',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const UrunListesiSayfasi(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GEÇİCİ VERİ — Gün 9'da bu blok silinecek, yerine
// API'den gelen gerçek ürünler kullanılacak.
// ─────────────────────────────────────────────────────────────
const sahteUrunler = <Urun>[
  Urun(ad: 'Kablosuz Kulaklık', kategori: 'Elektronik', fiyat: 1499.90, stok: 25),
  Urun(ad: 'Kablosuz Mouse', kategori: 'Elektronik', fiyat: 299.90, stok: 3),
  Urun(ad: 'Mekanik Klavye', kategori: 'Elektronik', fiyat: 899.90, stok: 0),
  Urun(ad: 'Akıllı Saat', kategori: 'Elektronik', fiyat: 2299.00, stok: 1),
  Urun(ad: 'Bluetooth Hoparlör', kategori: 'Elektronik', fiyat: 799.90, stok: 18),
  Urun(ad: 'Kahve Makinesi', kategori: 'Ev Aletleri', fiyat: 3499.00, stok: 7),
  Urun(ad: 'Su Isıtıcı', kategori: 'Ev Aletleri', fiyat: 649.90, stok: 12),
  Urun(ad: 'Tost Makinesi', kategori: 'Ev Aletleri', fiyat: 549.90, stok: 0),
];

class UrunListesiSayfasi extends StatelessWidget {
  const UrunListesiSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
      ),
      body: ListView.builder(
        itemCount: sahteUrunler.length,
        itemBuilder: (context, index) {
          return UrunKarti(urun: sahteUrunler[index]);
        },
      ),
    );
  }
}