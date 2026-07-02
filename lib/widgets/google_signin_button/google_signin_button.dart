// lib/widgets/google_signin_button/google_signin_button.dart
//
// Botão de "Entrar com Google" com implementação condicional por
// plataforma:
// - Na Web: renderiza o botão OFICIAL do Google (obrigatório desde a
//   migração para o FedCM/Google Identity Services — não é mais permitido
//   disparar o login a partir de um botão customizado na Web).
// - No mobile/desktop: usa um botão comum, estilizado igual ao resto do
//   app, que chama `GoogleAuthService.signIn()` diretamente.
//
// O import abaixo escolhe em tempo de compilação qual arquivo usar,
// então o pacote `google_sign_in_web` (que só existe pra Web) nunca é
// referenciado ao compilar pra iOS/Android — evita erro de build.
export 'google_signin_button_stub.dart'
    if (dart.library.js_interop) 'google_signin_button_web.dart';
