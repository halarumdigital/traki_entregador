import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _keyDriverId = 'driver_id';
  static const _keyAccessToken = 'access_token';
  static const _keyDriverData = 'driver_data';
  static const _keySessionCookie = 'session_cookie';
  static const _keyProfileImagePath = 'profile_image_path';
  static const _keyTodayDeliveries = 'today_deliveries';
  static const _keyTodayDeliveriesDate = 'today_deliveries_date';

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

  // Salvar caminho da imagem de perfil
  static Future<void> saveProfileImagePath(String imagePath) async {
    await _storage.write(key: _keyProfileImagePath, value: imagePath);
  }

  // Obter caminho da imagem de perfil
  static Future<String?> getProfileImagePath() async {
    return await _storage.read(key: _keyProfileImagePath);
  }

  // Salvar entregas de hoje
  static Future<void> saveTodayDeliveries(int count) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await Future.wait([
      _storage.write(key: _keyTodayDeliveries, value: count.toString()),
      _storage.write(key: _keyTodayDeliveriesDate, value: today),
    ]);
  }

  // Obter entregas de hoje (zera automaticamente se for um novo dia)
  static Future<int> getTodayDeliveries() async {
    final savedDate = await _storage.read(key: _keyTodayDeliveriesDate);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Se a data salva for diferente de hoje, zera o contador
    if (savedDate != today) {
      await saveTodayDeliveries(0);
      return 0;
    }

    final count = await _storage.read(key: _keyTodayDeliveries);
    return int.tryParse(count ?? '0') ?? 0;
  }

  // Incrementar entregas de hoje
  static Future<int> incrementTodayDeliveries() async {
    final current = await getTodayDeliveries();
    final newCount = current + 1;
    await saveTodayDeliveries(newCount);
    return newCount;
  }

  // Limpar sessão (logout)
  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyDriverId),
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyDriverData),
      _storage.delete(key: _keySessionCookie),
      _storage.delete(key: _keyProfileImagePath),
    ]);
  }
}
