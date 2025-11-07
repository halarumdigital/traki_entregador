import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../functions/functions.dart';
import '../styles/styles.dart';

class OnlineOfflineToggle extends StatefulWidget {
  const OnlineOfflineToggle({Key? key}) : super(key: key);

  @override
  State<OnlineOfflineToggle> createState() => _OnlineOfflineToggleState();
}

class _OnlineOfflineToggleState extends State<OnlineOfflineToggle> {
  bool isOnline = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final driverData = await LocalStorageService.getDriverData();
      if (driverData != null && mounted) {
        setState(() {
          isOnline = driverData['available'] ?? false;
        });
        debugPrint('📱 Status atual: ${isOnline ? "ONLINE" : "OFFLINE"}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar status: $e');
    }
  }

  Future<void> _toggleStatus(bool value) async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      debugPrint('🔄 Alterando status para: ${value ? "ONLINE" : "OFFLINE"}');

      final result = await toggleDriverAvailability(value);

      if (result == true) {
        if (mounted) {
          setState(() {
            isOnline = value;
          });

          // Atualizar dados locais
          final driverData = await LocalStorageService.getDriverData();
          if (driverData != null) {
            driverData['available'] = value;
            final token = await LocalStorageService.getAccessToken();
            await LocalStorageService.saveDriverSession(
              driverId: driverData['id'],
              accessToken: token ?? '',
              driverData: driverData,
            );
          }

          _showSnackbar(
            value ? '✅ Você está online!' : '⭕ Você está offline',
            value ? Colors.green : Colors.grey,
          );

          debugPrint('✅ Status alterado com sucesso');
        }
      } else {
        final message = result is String ? result : 'Erro ao atualizar status';
        if (mounted) {
          _showSnackbar('❌ $message', Colors.red);
        }
        debugPrint('❌ Falha ao alterar status: $message');
      }
    } catch (e) {
      debugPrint('❌ Erro ao alterar status: $e');
      if (mounted) {
        _showSnackbar('❌ Erro ao atualizar status', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [Color(0xFF4CAF50), Color(0xFF388E3C)]
              : [Color(0xFF9E9E9E), Color(0xFF616161)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            Switch(
              value: isOnline,
              onChanged: _toggleStatus,
              activeColor: Colors.white,
              activeTrackColor: Color(0xFF81C784),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Color(0xFFBDBDBD),
            ),
        ],
      ),
    );
  }
}
