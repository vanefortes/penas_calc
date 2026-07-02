// Implementação para Web: renderiza o botão OFICIAL do Google, exigido
// pelo Google Identity Services (FedCM). Não é possível customizar o
// visual desse botão além das opções oferecidas pelo próprio SDK.
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import '../../services/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final ValueChanged<GoogleUserData?> onSignedIn;
  const GoogleSignInButton({super.key, required this.onSignedIn});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // IMPORTANTE: o SDK do Google (`renderButton()`) só pode ser chamado
    // DEPOIS que `GoogleSignIn.instance.initialize()` terminar — senão o
    // botão fica preso indefinidamente em "Getting ready", sem erro
    // nenhum no console. Por isso esperamos a Future antes de desenhar.
    _initFuture = GoogleAuthService.ensureInitialized();
    GoogleAuthService.authDataStream.listen((user) {
      if (mounted) widget.onSignedIn(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 44,
            child: Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 44,
            child: Center(
              child: Text(
                'Erro ao carregar login Google:\n${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        // O SDK do Google desenha o próprio botão — não dá pra pintar de
        // dourado igual ao resto do app. IMPORTANTE: sem passar uma
        // configuração explícita, o pacote manda `null` em todos os
        // parâmetros (type/theme/size/text) na requisição do botão, o
        // que o Google rejeita com 403 "origin not allowed" num recurso
        // secundário (mesmo o login em si continuando a funcionar).
        return SizedBox(
          height: 44,
          child: web.renderButton(
            configuration: web.GSIButtonConfiguration(
              type: web.GSIButtonType.standard,
              theme: web.GSIButtonTheme.outline,
              size: web.GSIButtonSize.large,
              text: web.GSIButtonText.signinWith,
            ),
          ),
        );
      },
    );
  }
}
