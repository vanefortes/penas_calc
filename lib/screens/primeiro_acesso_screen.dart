// lib/screens/primeiro_acesso_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/google_auth_service.dart';
import '../services/apple_auth_service.dart';
import '../widgets/google_signin_button/google_signin_button.dart';

// Paleta local — independente do tema global
class _CP {
  static const navyDeep   = Color(0xFF050A18);
  static const navy       = Color(0xFF0B1530);
  static const gold       = Color(0xFFC9A961);
  static const goldBright = Color(0xFFF0D488);
  static const goldDeep   = Color(0xFF7A6230);
  static const cream      = Color(0xFFF3EEDB);
  static const textDim    = Color(0x9EE8DEC4);
  static const textFaint  = Color(0x57E8DEC4);
  // Cor sólida para o fundo dos campos (sem transparência)
  static const fieldBg    = Color(0xFF0D1A35);
}

class PrimeiroAcessoScreen extends StatefulWidget {
  const PrimeiroAcessoScreen({super.key});
  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _nome  = TextEditingController();
  final _oab   = TextEditingController();
  final _email = TextEditingController();
  bool _biometria = true;
  bool _googleLoading = false;
  bool _appleLoading = false;

  // Sign in with Apple só faz sentido em plataformas Apple.
  bool get _appleDisponivel =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    final user = await GoogleAuthService.signIn();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    _onGoogleResult(user);
  }

  /// Chamado tanto pelo fluxo mobile (após `_loginGoogle`) quanto pelo
  /// botão oficial do Google na Web (via stream de eventos de login).
  void _onGoogleResult(GoogleUserData? user) {
    if (user == null) return;
    setState(() {
      _nome.text  = user.nome;
      _email.text = user.email;
    });
    if (user.foto.isNotEmpty) {
      context.read<AppState>().setFotoPerfil(user.foto);
    }
  }

  Future<void> _loginApple() async {
    setState(() => _appleLoading = true);
    final user = await AppleAuthService.signIn();
    if (!mounted) return;
    setState(() => _appleLoading = false);
    if (user == null) return;
    setState(() {
      if (user.nome.isNotEmpty) _nome.text = user.nome;
      if (user.email.isNotEmpty) _email.text = user.email;
    });
  }

  @override
  void dispose() {
    _nome.dispose(); _oab.dispose(); _email.dispose();
    super.dispose();
  }

  bool _emailValido(String email) {
    return RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _oabValida(String oab) {
    if (oab.isEmpty) return true; // OAB é opcional
    return RegExp(
      r'^\d{1,6}\s*/\s*[A-Za-z]{2}$',
    ).hasMatch(oab.trim());
  }

  Future<void> _concluir() async {
    final nome  = _nome.text.trim();
    final email = _email.text.trim();
    final oab   = _oab.text.trim();

    if (nome.isEmpty) {
      _mostrarErro('O nome é obrigatório para continuar.');
      return;
    }

    if (email.isEmpty) {
      _mostrarErro('O e-mail é obrigatório para continuar.');
      return;
    }

    if (!_emailValido(email)) {
      _mostrarErro('Digite um e-mail válido. Ex: nome@dominio.com');
      return;
    }

    if (!_oabValida(oab)) {
      _mostrarErro('OAB inválida. Use o formato: 123456/SP');
      return;
    }

    final state = context.read<AppState>();
    await state.completarPrimeiroAcesso(
      nome: nome,
      oab: _oab.text.trim(),
      email: email,
      biometria: _biometria,
    );
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(mensagem, style: GoogleFonts.inter(fontSize: 13))),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _CP.navyDeep,
        body: Stack(children: [
          // Fundo gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_CP.navy, _CP.navyDeep],
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Center(
                  child: Text('C · P',
                    style: GoogleFonts.cinzel(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 11 * 0.28, color: _CP.goldBright,
                    )),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: Column(children: [
                    // Logo oficial
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 22, offset: Offset(0, 8)),
                          BoxShadow(color: Color(0x40C9A961), blurRadius: 14, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset('assets/logo.png', width: 110, height: 110, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('PRIMEIRO ACESSO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, letterSpacing: 10 * 0.32, color: _CP.goldBright,
                      )),
                    const SizedBox(height: 10),
                    Text('Configure seu perfil',
                      style: GoogleFonts.cinzel(
                        fontSize: 24, fontWeight: FontWeight.w600,
                        height: 1.2, color: _CP.cream,
                      )),
                    const SizedBox(height: 6),
                    Text('Suas informações ficam salvas localmente neste dispositivo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                        fontStyle: FontStyle.italic, fontSize: 14, color: _CP.textDim,
                      )),
                    const SizedBox(height: 6),
                    Text('* campos obrigatórios',
                      style: GoogleFonts.inter(
                        fontSize: 11, color: _CP.goldBright.withOpacity(0.7))),
                    const SizedBox(height: 26),
                    // Botão Google
                    if (kIsWeb)
                      GoogleSignInButton(onSignedIn: _onGoogleResult)
                    else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _googleLoading ? null : _loginGoogle,
                        icon: _googleLoading
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _CP.goldBright))
                            : const Icon(Icons.account_circle_rounded,
                                size: 20, color: _CP.goldBright),
                        label: Text(
                          _googleLoading
                              ? 'Conectando...'
                              : 'Preencher com conta Google',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: _CP.cream),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: _CP.goldDeep, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                    if (_appleDisponivel) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _appleLoading ? null : _loginApple,
                          icon: _appleLoading
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _CP.goldBright))
                              : const Icon(Icons.apple_rounded,
                                  size: 20, color: _CP.goldBright),
                          label: Text(
                            _appleLoading
                                ? 'Conectando...'
                                : 'Preencher com conta Apple',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: _CP.cream),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: _CP.goldDeep, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: Divider(color: _CP.goldDeep.withOpacity(0.5))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('ou preencha manualmente',
                          style: GoogleFonts.inter(
                            fontSize: 10, color: _CP.textFaint)),
                      ),
                      Expanded(child: Divider(color: _CP.goldDeep.withOpacity(0.5))),
                    ]),
                    _Field(label: 'Nome do(a) advogado(a) *', placeholder: 'Dr(a). seu nome',   controller: _nome,  autofocus: false),
                    _Field(label: 'OAB / UF',               placeholder: '123.456 / SP',        controller: _oab,   mono: true),
                    _Field(label: 'E-mail *',                placeholder: 'contato@escritorio.com', controller: _email, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _BiometriaCard(on: _biometria, onChanged: (v) => setState(() => _biometria = v)),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: _GoldButton(label: 'ACESSAR APLICATIVO', onTap: _concluir),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text.rich(TextSpan(
                  style: GoogleFonts.inter(fontSize: 11, color: _CP.textFaint),
                  children: [
                    const TextSpan(text: 'Ao continuar você concorda com os '),
                    TextSpan(text: 'termos de uso',
                      style: GoogleFonts.inter(fontSize: 11, color: _CP.goldBright)),
                  ],
                )),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Campo de texto completamente isolado do tema global ───────────
class _Field extends StatelessWidget {
  final String label, placeholder;
  final TextEditingController controller;
  final bool mono, autofocus;
  final TextInputType? keyboard;

  const _Field({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.mono = false,
    this.autofocus = false,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    // Texto e hint sempre legíveis, independente do tema global
    final textStyle  = mono
        ? GoogleFonts.jetBrainsMono(fontSize: 14, color: _CP.cream)
        : GoogleFonts.inter(fontSize: 14, color: _CP.cream);
    final hintStyle  = mono
        ? GoogleFonts.jetBrainsMono(fontSize: 14, color: _CP.textFaint)
        : GoogleFonts.inter(fontSize: 14, color: _CP.textFaint);
    final radius = BorderRadius.circular(11);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Label dourado
        Text(label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5, fontWeight: FontWeight.w600,
            letterSpacing: 10.5 * 0.16, color: _CP.goldBright,
          )),
        const SizedBox(height: 7),
        // Theme local que ANULA completamente o inputDecorationTheme global
        Theme(
          data: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: _CP.goldBright,
              onSurface: _CP.cream,
              surface: _CP.fieldBg,
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: _CP.goldBright,
              selectionColor: Color(0x44F0D488),
              selectionHandleColor: _CP.goldBright,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: _CP.fieldBg,          // navy sólido — nunca branco
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintStyle: hintStyle,
              border:         OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: _CP.goldDeep, width: 1)),
              enabledBorder:  OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: _CP.goldDeep, width: 1)),
              focusedBorder:  OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: _CP.goldBright, width: 1.5)),
              errorBorder:    OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Colors.red, width: 1)),
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: keyboard,
            cursorColor: _CP.goldBright,
            style: textStyle,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: hintStyle,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Toggle de biometria ───────────────────────────────────────────
class _BiometriaCard extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  const _BiometriaCard({required this.on, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!on),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _CP.goldDeep, width: 1),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Proteção biométrica',
              style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.w600, color: _CP.cream)),
            const SizedBox(height: 2),
            Text('Face ID / Touch ID ao abrir',
              style: GoogleFonts.inter(fontSize: 11, color: _CP.textDim)),
          ])),
          _Toggle(on: on),
        ]),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  const _Toggle({required this.on});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 42, height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: on ? const LinearGradient(colors: [_CP.goldDeep, _CP.goldBright]) : null,
        color: on ? null : const Color(0x80000000),
        border: Border.all(color: _CP.goldDeep, width: 1),
      ),
      child: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          left: on ? 20 : 2, top: 2,
          child: Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFF4D0),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Botão dourado ─────────────────────────────────────────────────
class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_CP.goldBright, _CP.goldDeep],
            ),
            boxShadow: const [BoxShadow(color: Color(0x73C9A961), blurRadius: 14, offset: Offset(0, 4))],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(label,
              style: GoogleFonts.cinzel(
                fontSize: 14, fontWeight: FontWeight.w700,
                letterSpacing: 14 * 0.16, color: _CP.navyDeep,
              )),
          ),
        ),
      ),
    );
  }
}
