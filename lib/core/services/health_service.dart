import 'package:health/health.dart';

class HealthService {
  static HealthService? _instance;
  static HealthService get instance => _instance ??= HealthService._();
  HealthService._();

  final _health = Health();
  bool _authorized = false;

  Future<bool> requestPermission() async {
    try {
      final types = [HealthDataType.WATER];
      final permissions = [HealthDataAccess.WRITE];
      _authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      return _authorized;
    } catch (_) {
      return false;
    }
  }

  Future<void> writeWaterIntake(int amountMl, DateTime timestamp) async {
    if (!_authorized) return;
    try {
      await _health.writeHealthData(
        value: amountMl.toDouble(),
        type: HealthDataType.WATER,
        startTime: timestamp,
        endTime: timestamp,
      );
    } catch (_) {}
  }
}
