import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _keyDriverId = 'driver_id';
  static const _keyAccessToken = 'access_token';
  static const _keyDriverData = 'driver_data';
  static const _keySessionCookie = 'session_cookie';

  // Salvar dados do motorista após cadastro/login
  static Future<void> saveDriverSession({
    required String driverId,
    required String accessToken,
    required Map<String, dynamic> driverData,
    String? sessionCookie,
  }) async {
    final futures = [
      _storage.write(key: _keyDriverId, value: driverId),
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyDriverData, value: jsonEncode(driverData)),
    ];

    if (sessionCookie != null) {
      futures.add(_storage.write(key: _keySessionCookie, value: sessionCookie));
    }

    await Future.wait(futures);
  }

  // Obter ID do motorista
  static Future<String?> getDriverId() async {
    return await _storage.read(key: _keyDriverId);
  }

  // Obter token de acesso
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // Obter dados completos do motorista
  static Future<Map<String, dynamic>?> getDriverData() async {
    final data = await _storage.read(key: _keyDriverData);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // Obter cookie de sessão
  static Future<String?> getSessionCookie() async {
    return await _storage.read(key: _keySessionCookie);
  }

  // Salvar cookie de sessão
  static Future<void> saveSessionCookie(String cookie) async {
    await _storage.write(key: _keySessionCookie, value: cookie);
  }

  // Verificar se tem sessão ativa
  static Future<bool> hasActiveSession() async {
    final driverId = await getDriverId();
    final token = await getAccessToken();
    return driverId != null && token != null;
  }

  // Limpar sessão (logout)
  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyDriverId),
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyDriverData),
      _storage.delete(key: _keySessionCookie),
    ]);
  }
}
