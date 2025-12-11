// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:myjanji_v2/main.dart';
import 'package:myjanji_v2/services/contract_service.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Initialize contract service with dummy contracts
    ContractService.initializeDummyContracts();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyJanjiApp());

    // Verify that the login screen is displayed
    expect(find.text('Sign In to MyJanji'), findsOneWidget);
    expect(find.text('Upload Your IC Photo'), findsOneWidget);
    expect(find.text('Select IC Photo'), findsOneWidget);
  });
}
