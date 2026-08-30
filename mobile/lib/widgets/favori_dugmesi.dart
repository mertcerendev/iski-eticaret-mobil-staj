import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/urun.dart';
import '../providers/favori_provider.dart';

/// Kalp düğmesi. Hem ürün kartında hem detay ekranında kullanılır.
class FavoriDugmesi extends StatelessWidget {
  final Urun urun;

  /// Detay ekranında koyu başlık üzerinde durduğu için beyaz istenir.
  /// Kartta varsayılan renk kullanılır.
  final Color? renk;

  const FavoriDugmesi({super.key, required this.urun, this.renk});

  Future<void> _degistir(BuildContext context) async {
    final mesajci = ScaffoldMessenger.of(context);
    final tema = Theme.of(context);

    final hata = await context.read<FavoriProvider>().degistir(urun);

    if (hata == null) return;

    // İstek başarısız oldu; sağlayıcı kalbi eski hâline döndürdü, kullanıcıya
    // nedenini söylemek kalıyor.
    mesajci.hideCurrentSnackBar();
    mesajci.showSnackBar(
      SnackBar(content: Text(hata), backgroundColor: tema.colorScheme.error),
    );
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
