import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/widgets/urun_karti.dart';

void main() {
  testWidgets('Ürün listesi ekranı ürün kartlarıyla çizilir', (tester) async {
    await tester.pumpWidget(const UygulamaKoku());

    expect(find.text('Ürünler'), findsOneWidget);

    expect(find.byType(UrunKarti), findsWidgets);

    expect(find.text('Kablosuz Kulaklık'), findsOneWidget);
    expect(find.text('1499.90 TL'), findsOneWidget);
  });
}