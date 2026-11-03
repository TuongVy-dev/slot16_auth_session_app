import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:slot16_auth_session_app/main.dart';
import 'package:slot16_auth_session_app/services/session_service.dart';

bool canPop(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator)).canPop();

Future<void> login(WidgetTester tester, String user, String pass) async {
  await tester.enterText(find.byType(TextFormField).at(0), user);
  await tester.enterText(find.byType(TextFormField).at(1), pass);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Validation + login sai → SnackBar "Login failed"',
      (tester) async {
    await tester.pumpWidget(const MyApp(initialLoggedIn: false));
    await tester.pumpAndSettle();

    await login(tester, '', '12');
    expect(find.text('Enter username'), findsOneWidget);
    expect(find.text('Password too short'), findsOneWidget);

    await login(tester, 'admin', '9999');
    expect(find.text('Login failed'), findsOneWidget);
    expect(await SessionService.isLoggedIn(), isFalse);
  });

  testWidgets('Login đúng → Dashboard → Profile → Logout không back lại được',
      (tester) async {
    await tester.pumpWidget(const MyApp(initialLoggedIn: false));
    await tester.pumpAndSettle();
    expect(canPop(tester), isFalse); // không có trang "/" (404) nằm dưới

    await login(tester, 'admin', '1234');
    expect(find.text('Welcome to Dashboard'), findsOneWidget);
    expect(await SessionService.isLoggedIn(), isTrue);
    expect(canPop(tester), isFalse); // không back về Login

    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle();
    expect(find.text('User Profile'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);
    expect(canPop(tester), isFalse); // không back về Profile/Dashboard
    expect(await SessionService.isLoggedIn(), isFalse);
  });

  testWidgets('Restart khi đã login → vào thẳng Dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({'isLoggedIn': true});
    await tester.pumpWidget(
        MyApp(initialLoggedIn: await SessionService.isLoggedIn()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Dashboard'), findsOneWidget);
    expect(canPop(tester), isFalse);
  });

  testWidgets('Guard: chưa login mở /profile → bị đẩy về Login',
      (tester) async {
    await tester.pumpWidget(const MyApp(initialLoggedIn: false));
    await tester.pumpAndSettle();

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/profile');
    await tester.pumpAndSettle();

    expect(find.text('User Profile'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
