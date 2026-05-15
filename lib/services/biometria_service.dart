// lib/services/biometria_service.dart
// Serviço que encapsula a autenticação biométrica via local_auth.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';

class BiometriaService {
  static final _auth = LocalAuthentication();

  /// Verifica se o dispositivo suporta biometria.
  static Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Solicita autenticação biométrica.
  /// Retorna true se autenticado com sucesso.
  static Future<bool> autenticar() async {
    if (kIsWeb) return true;
    try {
      final suportado = await isSupported();
      if (!suportado) return true; // sem suporte = libera o acesso

      return await _auth.authenticate(
        localizedReason: 'Autentique-se para acessar a Calculadora Penal',
        options: const AuthenticationOptions(
          biometricOnly: false, // permite PIN como fallback
          stickyAuth: true,     // mantém o diálogo em caso de troca de app
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
