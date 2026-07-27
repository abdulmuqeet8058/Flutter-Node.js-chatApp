import 'package:flutter_chat_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login when there is no saved session', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ChatApp());
    await tester.pumpAndSettle();

    expect(find.text('Ping'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
