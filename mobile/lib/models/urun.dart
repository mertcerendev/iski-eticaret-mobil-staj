class Urun {
    final String ad;
    final String kategori;
    final double fiyat;
    final int stok;
    final String? gorselUrl;

    const Urun({
        required this.ad,
        required this.kategori,
        required this.fiyat,
        required this.stok,
        this.gorselUrl,
    });

    bool get stoktaVar => stok > 0;
    bool get sonUrunler => stok > 0 && stok < 5;

    String get stokMetni {
        if (!stoktaVar) return 'Tükendi';
        if (sonUrunler) return 'Son $stok adet';
        return 'Stokta';
    } 
}