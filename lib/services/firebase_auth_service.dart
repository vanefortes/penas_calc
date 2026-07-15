// lib/services/firebase_auth_service.dart
// Camada fina de integração com o Firebase Authentication.
//
// Este serviço NÃO conhece Google Sign-In, Apple Sign-In nem UI — ele só
// sabe conversar com o Firebase. Quem já sabe autenticar com um provedor
// (ex: `GoogleAuthService`) passa as credenciais pra cá, e este serviço
// troca isso por uma sessão oficial do Firebase (com UID permanente).
//
// Uso típico:
//
//   final googleData = await GoogleAuthService.signIn();
//   if (googleData != null) {
//     await FirebaseAuthService.instance.signInWithGoogleCredential(
//       idToken: googleData.idToken,
//       accessToken: googleData.accessToken,
//     );
//   }

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Usuário Firebase atualmente autenticado (ou `null`).
  User? get currentUser => _auth.currentUser;

  /// Stream que emite sempre que o estado de login muda (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Troca as credenciais do Google Sign-In por uma sessão do Firebase.
  ///
  /// [idToken] é obrigatório para o Firebase reconhecer a identidade.
  /// [accessToken] é opcional, mas recomendado quando disponível.
  Future<UserCredential> signInWithGoogleCredential({
    required String? idToken,
    String? accessToken,
  }) {
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Troca as credenciais do Sign in with Apple por uma sessão do Firebase.
  ///
  /// [idToken] é o identityToken retornado pela Apple. [rawNonce] é o
  /// valor original (não criptografado) do nonce gerado antes da
  /// autorização — necessário para o Firebase validar que o token não foi
  /// reaproveitado (proteção contra replay attack).
  Future<UserCredential> signInWithAppleCredential({
    required String? idToken,
    required String rawNonce,
  }) {
    final credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Encerra a sessão do usuário no Firebase.
  /// Não faz logout do Google/Apple — isso continua responsabilidade de
  /// cada serviço de provedor (`GoogleAuthService.signOut()`, etc.).
  Future<void> signOut() => _auth.signOut();

  /// Identificador do provedor usado no login atual (ex: `google.com`,
  /// `apple.com`, `password`), ou `null` se não houver usuário logado.
  /// Usado para saber como reautenticar antes de uma ação sensível (como
  /// excluir a conta).
  String? get currentProviderId {
    final providers = _auth.currentUser?.providerData ?? const [];
    return providers.isEmpty ? null : providers.first.providerId;
  }

  /// Reautentica o usuário atual com uma nova credencial do Google.
  /// Necessário quando o Firebase recusa uma ação sensível (ex: excluir a
  /// conta) por falta de login recente (`requires-recent-login`).
  Future<void> reauthenticateWithGoogleCredential({
    required String? idToken,
    String? accessToken,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Reautentica o usuário atual com uma nova credencial da Apple.
  Future<void> reauthenticateWithAppleCredential({
    required String? idToken,
    required String rawNonce,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Reautentica o usuário atual com e-mail e senha.
  Future<void> reauthenticateWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Exclui definitivamente a conta do usuário atual no Firebase.
  ///
  /// Se a sessão não for recente o bastante, lança `FirebaseAuthException`
  /// com código `requires-recent-login` — nesse caso, reautentique (ver
  /// os métodos `reauthenticateWith...` acima) e chame de novo.
  Future<void> deleteCurrentUser() async {
    await _auth.currentUser?.delete();
  }
}
