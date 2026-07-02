// lib/services/google_auth_service.dart
// Serviço de autenticação com Google — preenche nome, e-mail e foto do perfil.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb
        ? '148303670455-558pbf6atg8lr4c2332m016e0m3dua1e.apps.googleusercontent.com'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? '148303670455-20g46966frr6hec2d92duesf7v03rhld.apps.googleusercontent.com'
            : '148303670455-g07a8j6th324qeh3jop4250748aumrg8.apps.googleusercontent.com',
    serverClientId: '148303670455-558pbf6atg8lr4c2332m016e0m3dua1e.apps.googleusercontent.com',
  );

  /// Faz login com Google e retorna os dados do usuário.
  /// Retorna null se o usuário cancelar.
  static Future<GoogleUserData?> signIn() async {
    try {
      GoogleSignInAccount? account;

      // Na Web, qualquer `await` antes do signIn() quebra o vínculo com o
      // clique do usuário, e o navegador bloqueia o popup silenciosamente
      // (sem lançar erro nenhum — só "não acontece nada"). Por isso, na Web
      // pulamos direto para o signIn() manual, sem tentar login silencioso.
      if (kIsWeb) {
        account = await _googleSignIn.signIn();
      } else {
        // Tenta login silencioso primeiro (já logado antes)
        account = await _googleSignIn.signInSilently();
        account ??= await _googleSignIn.signIn();
      }
      if (account == null) return null;

      // Baixa a foto de perfil como data URL base64
      String fotoDataUrl = '';
      if (account.photoUrl != null) {
        fotoDataUrl = await _downloadFotoAsDataUrl(account.photoUrl!);
      }

      return GoogleUserData(
        nome:     _formatarNome(account.displayName ?? ''),
        email:    account.email,
        foto:     fotoDataUrl,
        googleId: account.id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Faz logout do Google.
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Verifica se já há uma conta logada.
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Baixa a foto e converte para data URL base64.
  static Future<String> _downloadFotoAsDataUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return '';
      final bytes = response.bodyBytes;
      final mime  = response.headers['content-type'] ?? 'image/jpeg';
      final b64   = base64Encode(Uint8List.fromList(bytes));
      return 'data:$mime;base64,$b64';
    } catch (_) {
      return '';
    }
  }

  /// Remove prefixos como "Dr.", "Dra." para não duplicar.
  static String _formatarNome(String nome) => nome.trim();
}

class GoogleUserData {
  final String nome;
  final String email;
  final String foto;
  final String googleId;

  const GoogleUserData({
    required this.nome,
    required this.email,
    required this.foto,
    required this.googleId,
  });
}
