import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favori_provider.dart';
import '../widgets/durum_gorunumleri.dart';
import '../widgets/urun_karti.dart';
import 'urun_detay_ekrani.dart';

class FavorilerEkrani extends StatelessWidget {
  const FavorilerEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final saglayici = context.watch<FavoriProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: _icerik(context, saglayici),
    );
  }

  Widget _icerik(BuildContext context, FavoriProvider saglayici) {
    if (saglayici.yukleniyor && saglayici.favoriUrunler.isEmpty) {
      return const YukleniyorGorunumu();
    }

    if (saglayici.hata != null && saglayici.favoriUrunler.isEmpty) {
      return HataGorunumu(
        mesaj: saglayici.hata!,
        onTekrarDene: saglayici.yukle,
      );
    }

    if (saglayici.favoriUrunler.isEmpty) {
      return const BosGorunumu(
        baslik: 'Henüz favoriniz yok',
        aciklama:
            'Beğendiğiniz ürünlerin kalp simgesine dokunarak buraya ekleyebilirsiniz.',
      );
    }

    return RefreshIndicator(
      onRefresh: saglayici.yukle,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: saglayici.favoriUrunler.length,
        itemBuilder: (context, sira) {
          final urun = saglayici.favoriUrunler[sira];

          return UrunKarti(
            urun: urun,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => UrunDetayEkrani(urun: urun)),
            ),
          );
        },
      ),
    );
  }
}
