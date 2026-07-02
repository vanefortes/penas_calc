// Implementação para mobile/desktop.
// Nessas plataformas o login continua sendo disparado por um botão comum
// do próprio app (ver telas que usam `GoogleAuthService.signIn()`
// diretamente) — esse widget não é usado na prática fora da Web, mas
// existe pra manter a mesma API em ambos os branches de compilação.
import 'package:flutter/widgets.dart';
import '../../services/google_auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
  final ValueChanged<GoogleUserData?> onSignedIn;
  const GoogleSignInButton({super.key, required this.onSignedIn});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
