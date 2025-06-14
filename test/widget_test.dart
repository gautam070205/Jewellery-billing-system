import 'package:flutter_test/flutter_test.dart';
import 'package:jwellery_billing/main.dart';

void main() {
  testWidgets('Jewelry Inventory Management App loads correctly',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(JewelryInventoryApp());

    // Verify that our app title appears
    expect(find.text('Jewelry Inventory Management'), findsOneWidget);
    expect(find.text('Billing'), findsOneWidget);

    // Verify the sidebar menu items appear
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify billing steps appear
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
  });
}
