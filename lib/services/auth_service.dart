import 'session_service.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    if (username == "admin" && password == "1234") {
      await SessionService.saveSession(true);
      return true;
    }
    return false;
  }
}
