import 'package:flutter/material.dart';

import 'guards/auth_guard.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logged = await SessionService.isLoggedIn();
  runApp(MyApp(initialLoggedIn: logged));
}

class MyApp extends StatelessWidget {
  final bool initialLoggedIn;

  const MyApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Session Demo',
      debugShowCheckedModeBanner: false,
      initialRoute: initialLoggedIn ? "/dashboard" : "/login",
      onGenerateRoute: (settings) {
        // 1) Route thường
        if (settings.name == "/login") {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        if (settings.name == "/dashboard") {
          return MaterialPageRoute(builder: (_) => const DashboardScreen());
        }

        // 2) Route cần guard
        if (settings.name == "/profile") {
          return MaterialPageRoute(
            builder: (_) {
              return FutureBuilder<bool>(
                future: AuthGuard.check(),
                builder: (context, snapshot) {
                  // Loading state (đợi đọc SharedPreferences)
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final ok = snapshot.data!;
                  if (!ok) {
                    // Chưa login -> redirect login
                    // Dùng post-frame để tránh lỗi setState trong build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacementNamed(context, "/login");
                    });

                    return const Scaffold(
                      body: Center(child: Text("Redirecting to Login...")),
                    );
                  }

                  return const ProfileScreen();
                },
              );
            },
          );
        }

        // Trả null để route lạ rơi vào onUnknownRoute. Nếu trả trang 404 ở đây,
        // initialRoute "/dashboard" sẽ tự tạo thêm route "/" = 404 nằm dưới stack.
        return null;
      },
      // 3) Unknown route fallback
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text("404 - Route not found")),
        ),
      ),
    );
  }
}
