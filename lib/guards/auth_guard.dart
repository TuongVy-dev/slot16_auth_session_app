import '../services/session_service.dart';

class AuthGuard {
  static Future<bool> check() async {
    return await SessionService.isLoggedIn();
  }
}
