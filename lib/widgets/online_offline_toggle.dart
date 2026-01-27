import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../functions/functions.dart';

class OnlineOfflineToggle extends StatefulWidget {
  const OnlineOfflineToggle({super.key});

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
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Carregando...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isOnline,
            onChanged: _toggleStatus,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF4CAF50),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFBDBDBD),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isOnline ? 'Ativo' : 'Inativo',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
