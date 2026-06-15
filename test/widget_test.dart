import 'package:flutter_test/flutter_test.dart';
import 'package:organiza_compras/controllers/purchase_controller.dart';
import 'package:organiza_compras/main.dart';

void main() {
  testWidgets('App renders home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final controller = PurchaseController();
    await tester.pumpWidget(MyApp(controller: controller));

    // Verify that our app name exists on the home screen.
    expect(find.text('Organiza Compras'), findsOneWidget);
  });
}
