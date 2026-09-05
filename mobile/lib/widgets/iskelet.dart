import 'package:flutter/material.dart';

/// Yükleme sırasında içeriğin yerini tutan, hafifçe parlayan gri blok.
///
/// **Neden dönen halka değil?** Dönen halka "bir şey oluyor" der ama neyin
/// geleceğini söylemez; ekran yükleme bitince zıplar. İskelet, gelecek
/// içeriğin şeklini önceden çizdiği için bekleme daha kısa hissettiriyor ve
/// yerleşim oturduğunda kayma olmuyor.
class Iskelet extends StatefulWidget {
  final double? genislik;
  final double yukseklik;
  final double yuvarlaklik;

  const Iskelet({
    super.key,
    this.genislik,
    required this.yukseklik,
    this.yuvarlaklik = 8,
  });

  @override
  State<Iskelet> createState() => _IskeletDurumu();
}

class _IskeletDurumu extends State<Iskelet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _denetleyici;

  @override
  void initState() {
    super.initState();

    _denetleyici = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Yinelenen animasyon ekranla birlikte durdurulmalı; yoksa widget
    // ağaçtan çıktıktan sonra da kare üretmeye devam eder.
    _denetleyici.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _denetleyici,
      builder: (context, _) {
        return Container(
          width: widget.genislik,
          height: widget.yukseklik,
          decoration: BoxDecoration(
            // Açıktan koyuya gidip gelen gri: dikkat çekmeden "yükleniyor"
            // hissi veriyor.
            color: Color.lerp(
              Colors.grey.shade200,
              Colors.grey.shade300,
              _denetleyici.value,
            ),
            borderRadius: BorderRadius.circular(widget.yuvarlaklik),
          ),
        );
      },
    );
  }
}

/// Ürün kartının iskelet karşılığı: görsel alanı, iki satır yazı ve fiyat.
///
/// Ölçüler gerçek kartla aynı tutuldu; içerik gelince yerleşim kaymıyor.
class UrunKartiIskeleti extends StatelessWidget {
  const UrunKartiIskeleti({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 1,
            child: Iskelet(yukseklik: double.infinity, yuvarlaklik: 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Iskelet(yukseklik: 13),
                SizedBox(height: 6),
                Iskelet(genislik: 90, yukseklik: 11),
                SizedBox(height: 10),
                Iskelet(genislik: 70, yukseklik: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ürün ızgarasının iskelet hâli.
///
/// Ekranı dolduracak kadar kart çiziliyor; gerçek sayı bilinmediği için
/// sabit bir değer yeterli.
class IzgaraIskeleti extends StatelessWidget {
  final int adet;

  const IzgaraIskeleti({super.key, this.adet = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.61,
      ),
      itemCount: adet,
      itemBuilder: (_, _) => const UrunKartiIskeleti(),
    );
  }
}
