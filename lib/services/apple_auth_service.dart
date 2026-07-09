// lib/services/apple_auth_service.dart
// Serviço de autenticação com Apple — preenche nome e e-mail do perfil.
// Existe para cumprir a Guideline 4.8 da App Store: apps que oferecem login
// social (aqui, Google) precisam oferecer "Sign in with Apple" como opção
// equivalente.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  static const _prefsPrefix = 'apple_auth_';

  /// Faz login com Apple e retorna os dados do usuário.
  /// Retorna null se o usuário cancelar ou a operação falhar.
  ///
  /// IMPORTANTE: a Apple só envia nome e e-mail na PRIMEIRA autorização
  /// que o usuário concede a este app (identificado pelo Bundle ID). Em
  /// autorizações seguintes — mesmo em instalações/builds diferentes — esses
  /// campos vêm vazios de propósito, por design de privacidade da Apple.
  ///
  /// Por isso salvamos nome/e-mail localmente na primeira vez, associados
  /// ao `userIdentifier` (que é sempre enviado, em toda autorização). Nas
  /// vezes seguintes, se a Apple não reenviar nome/e-mail, recuperamos o
  /// que já foi salvo — evitando que o login "pareça" ter falhado.
  static Future<AppleUserData?> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final appleId = credential.userIdentifier ?? '';

      var nome = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ').trim();

      // Se o usuário optar por "Ocultar meu e-mail", a Apple retorna um
      // endereço de retransmissão (@privaterelay.appleid.com), que
      // funciona normalmente para fins de identificação do perfil.
      var email = credential.email ?? '';

      if (appleId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        if (nome.isNotEmpty || email.isNotEmpty) {
          // Primeira autorização: salva os dados para reuso futuro.
          if (nome.isNotEmpty) {
            await prefs.setString('$_prefsPrefix${appleId}_nome', nome);
          }
          if (email.isNotEmpty) {
            await prefs.setString('$_prefsPrefix${appleId}_email', email);
          }
        } else {
          // Autorizações seguintes: recupera o que foi salvo antes.
          nome = prefs.getString('$_prefsPrefix${appleId}_nome') ?? '';
          email = prefs.getString('$_prefsPrefix${appleId}_email') ?? '';
        }
      }

      return AppleUserData(
        nome: nome,
        email: email,
        appleId: appleId,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Usuário cancelou o fluxo (code == userCancelled) — não é um erro a
      // ser exibido. Qualquer outro código aqui é um erro real (ex.: 1000 =
      // capability/provisioning mal configurada no Developer Portal).
      // ignore: avoid_print
      print('SignInWithApple falhou: code=${e.code} message=${e.message}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('SignInWithApple erro inesperado: $e');
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
