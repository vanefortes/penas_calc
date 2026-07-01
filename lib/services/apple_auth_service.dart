// lib/services/apple_auth_service.dart
// Serviço de autenticação com Apple — preenche nome e e-mail do perfil.
// Existe para cumprir a Guideline 4.8 da App Store: apps que oferecem login
// social (aqui, Google) precisam oferecer "Sign in with Apple" como opção
// equivalente.

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  /// Faz login com Apple e retorna os dados do usuário.
  /// Retorna null se o usuário cancelar ou a operação falhar.
  ///
  /// IMPORTANTE: a Apple só envia nome e e-mail na PRIMEIRA autorização
  /// que o usuário concede a este app. Em autorizações seguintes, esses
  /// campos vêm vazios — por isso preenchemos os controllers apenas
  /// quando os valores não estiverem vazios, preservando o que já
  /// estava digitado.
  static Future<AppleUserData?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final nome = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ').trim();

      return AppleUserData(
        nome: nome,
        // Se o usuário optar por "Ocultar meu e-mail", a Apple retorna um
        // endereço de retransmissão (@privaterelay.appleid.com), que
        // funciona normalmente para fins de identificação do perfil.
        email: credential.email ?? '',
        appleId: credential.userIdentifier ?? '',
      );
    } on SignInWithAppleAuthorizationException {
      // Usuário cancelou o fluxo — não é um erro a ser exibido.
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifica se Sign in with Apple está disponível neste dispositivo/plataforma.
  static Future<bool> isAvailable() => SignInWithApple.isAvailable();
}

class AppleUserData {
  final String nome;
  final String email;
  final String appleId;

  const AppleUserData({
    required this.nome,
    required this.email,
    required this.appleId,
  });
}
