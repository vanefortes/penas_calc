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

  /// Encerra a sessão do usuário no Firebase.
  /// Não faz logout do Google/Apple — isso continua responsabilidade de
  /// cada serviço de provedor (`GoogleAuthService.signOut()`, etc.).
  Future<void> signOut() => _auth.signOut();
}
