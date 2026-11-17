import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gere_estra_ecommerce/main.dart';
import 'package:gere_estra_ecommerce/services/storage_service.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    await tester.pumpWidget(MyApp(storage: storage));

    // Verifica que los textos del login aparezcan.
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('INGRESAR'), findsOneWidget);
  });
}
