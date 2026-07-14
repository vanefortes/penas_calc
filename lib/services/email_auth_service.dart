// lib/services/email_auth_service.dart
// Serviço de autenticação por Email/senha via Firebase.
//
// Fica separado do `FirebaseAuthService` (que cuida de login social, ex:
// Google) para manter cada arquivo com uma responsabilidade única e fácil
// de testar. Ambos falam com a mesma instância de `FirebaseAuth`, então o
// usuário autenticado é o mesmo independentemente de qual serviço foi
// usado para entrar.
//
// Erros são propagados como `FirebaseAuthException` — trate-os na UI para
// mostrar mensagens amigáveis (ex: e-mail já em uso, senha fraca, etc.).

import 'package:firebase_auth/firebase_auth.dart';

class EmailAuthService {
  EmailAuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Cria uma nova conta com e-mail e senha.
  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Autentica um usuário existente com e-mail e senha.
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Envia e-mail de redefinição de senha.
  static Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Envia (ou reenvia) o e-mail de verificação para o usuário logado.
  /// Não faz nada se já não houver usuário logado ou se o e-mail já
  /// estiver verificado.
  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Recarrega os dados do usuário logado e retorna se o e-mail já foi
  /// verificado. Use isso antes de liberar o acesso ao app depois de um
  /// cadastro ou login por e-mail/senha.
  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Encerra a sessão do usuário no Firebase.
  static Future<void> signOut() => _auth.signOut();
}
