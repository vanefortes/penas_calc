// lib/services/google_auth_service.dart
// Serviço de autenticação com Google — preenche nome, e-mail e foto do perfil.
//
// A partir do google_sign_in 7.x, o Google exige o novo fluxo baseado em
// FedCM/Google Identity Services. Na Web, isso significa que NÃO é mais
// permitido abrir o login a partir de um botão customizado do app: é
// obrigatório usar o botão oficial renderizado pelo próprio SDK do Google
// (ver `lib/widgets/google_signin_button/`). No mobile (iOS/Android), o
// fluxo de login continua podendo ser disparado por um botão comum, via
// `GoogleAuthService.signIn()`.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleSignIn _instance = GoogleSignIn.instance;

  static bool _initialized = false;
  static Future<void>? _initializing;

  static final StreamController<GoogleUserData?> _authDataController =
      StreamController<GoogleUserData?>.broadcast();

  /// Emite os dados do usuário sempre que um login (mobile ou Web) é
  /// concluído com sucesso. Use isso para popular a UI na Web, onde o
  /// login é feito pelo botão oficial do Google (não por `signIn()`).
  static Stream<GoogleUserData?> get authDataStream => _authDataController.stream;

  /// Client ID conforme a plataforma.
  static String get _clientId {
    if (kIsWeb) {
      return '148303670455-558pbf6atg8lr4c2332m016e0m3dua1e.apps.googleusercontent.com';
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? '148303670455-20g46966frr6hec2d92duesf7v03rhld.apps.googleusercontent.com'
        : '148303670455-g07a8j6th324qeh3jop4250748aumrg8.apps.googleusercontent.com';
  }

  static const String _serverClientId =
      '148303670455-558pbf6atg8lr4c2332m016e0m3dua1e.apps.googleusercontent.com';

  /// Inicializa o SDK do Google Sign-In. Idempotente — pode ser chamado
  /// várias vezes (ex: no main.dart e de novo antes de cada login) sem
  /// problema, só inicializa de fato na primeira vez.
  static Future<void> ensureInitialized() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _doInitialize();
  }

  static Future<void> _doInitialize() async {
    await _instance.initialize(
      clientId: _clientId,
      // Na Web, o plugin recusa (assertion error) se `serverClientId` for
      // enviado — só é suportado no mobile.
      serverClientId: kIsWeb ? null : _serverClientId,
    );
    _instance.authenticationEvents.listen(
      _handleAuthEvent,
      onError: (Object _) {},
    );
    _initialized = true;
  }

  static void _handleAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      _emitUserData(event.user);
    } else {
      _authDataController.add(null);
    }
  }

  static Future<void> _emitUserData(GoogleSignInAccount account) async {
    _authDataController.add(await _toUserData(account));
  }

  /// Faz login com Google e retorna os dados do usuário.
  /// Só funciona em plataformas que suportam `authenticate()` (mobile).
  /// Na Web, use o widget de botão oficial (ver
  /// `lib/widgets/google_signin_button/`) — ele dispara o login sozinho e
  /// os dados chegam via [authDataStream].
  static Future<GoogleUserData?> signIn() async {
    await ensureInitialized();
    if (!_instance.supportsAuthenticate()) return null;
    try {
      final GoogleSignInAccount account = await _instance.authenticate();
      return await _toUserData(account);
    } catch (_) {
      return null;
    }
  }

  /// Faz logout do Google.
  static Future<void> signOut() async {
    try {
      await ensureInitialized();
      await _instance.signOut();
    } catch (_) {}
  }

  static Future<GoogleUserData> _toUserData(GoogleSignInAccount account) async {
    String fotoDataUrl = '';
    if (account.photoUrl != null) {
      fotoDataUrl = await _downloadFotoAsDataUrl(account.photoUrl!);
    }
    return GoogleUserData(
      nome: _formatarNome(account.displayName ?? ''),
      email: account.email,
      foto: fotoDataUrl,
      googleId: account.id,
    );
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
