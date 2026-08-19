import 'package:flutter/material.dart';
import '../models/urun.dart';

class UrunKarti extends StatelessWidget {
  final Urun urun;

  const UrunKarti({super.key, required this.urun});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Görsel yer tutucu
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_outlined, color: Colors.grey),
            ),

            const SizedBox(width: 12),

            // Ad, kategori, fiyat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urun.ad,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    urun.kategori,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${urun.fiyat.toStringAsFixed(2)} TL',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Stok durumu
            Text(
              urun.stokMetni,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: urun.stoktaVar ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}