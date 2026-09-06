import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/bildirim.dart';
import '../models/urun.dart';
import '../providers/favori_provider.dart';
import '../screens/giris_ekrani.dart';

/// Kalp düğmesi. Hem ürün kartında hem detay ekranında kullanılır.
class FavoriDugmesi extends StatelessWidget {
  final Urun urun;

  /// Detay ekranında koyu başlık üzerinde durduğu için beyaz istenir.
  /// Kartta varsayılan renk kullanılır.
  final Color? renk;

  const FavoriDugmesi({super.key, required this.urun, this.renk});

  Future<void> _degistir(BuildContext context) async {
    // Bu bir StatelessWidget; `mounted` denetimi yok, bu yüzden bildirim
    // aracı `await`ten ÖNCE hazırlanıyor.
    final bildir = Bildirim(context);

    // Favori ucu sunucuda oturum istiyor; misafir kullanıcı önce giriş
    // ekranına yönlendiriliyor.
    final girisVar = await oturumGerekli(
      context,
      'Beğendiğiniz ürünleri kaydetmek için hesabınıza giriş yapın.',
    );

    if (!girisVar || !context.mounted) return;

    final hata = await context.read<FavoriProvider>().degistir(urun);

    // İstek başarısız olduysa sağlayıcı kalbi eski hâline döndürdü;
    // kullanıcıya nedenini söylemek kalıyor.
    if (hata != null) bildir.hata(hata);
  }

  @override
  Widget build(BuildContext context) {
    // `select` yalnızca bu ürünün favori durumunu dinler. `watch` kullansaydık
    // herhangi bir favori değiştiğinde ekrandaki bütün kalpler yeniden
    // çizilirdi; burada yalnızca durumu değişen kart çizilir.
    final favoride = context.select<FavoriProvider, bool>(
      (saglayici) => saglayici.favoriMi(urun.id),
    );

    return IconButton(
      tooltip: favoride ? 'Favorilerden çıkar' : 'Favorilere ekle',
      icon: Icon(
        favoride ? Icons.favorite : Icons.favorite_border,
        color: favoride ? Colors.red.shade600 : renk,
      ),
      onPressed: () => _degistir(context),
    );
  }
}
