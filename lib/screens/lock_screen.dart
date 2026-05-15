// lib/screens/lock_screen.dart
// Tela de bloqueio exibida ao abrir o app quando a biometria está ativa.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/biometria_service.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  bool _desbloqueado = false;
  bool _autenticando = false;
  bool _falhou       = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autenticar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-bloqueia ao voltar do background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => _desbloqueado = false);
    } else if (state == AppLifecycleState.resumed && !_desbloqueado) {
      _autenticar();
    }
  }

  Future<void> _autenticar() async {
    if (_autenticando) return;
    setState(() { _autenticando = true; _falhou = false; });

    final ok = await BiometriaService.autenticar();

    if (!mounted) return;
    setState(() {
      _autenticando  = false;
      _desbloqueado  = ok;
      _falhou        = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_desbloqueado) return widget.child;

    final primary = const Color(0xFFC9A961);

    return Scaffold(
      backgroundColor: const Color(0xFF050A18),
      body: Stack(children: [
        // Fundo gradiente
        Container(decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2), radius: 1.1,
            colors: [Color(0xFF142447), Color(0xFF050A18)],
          ),
        )),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone de cadeado
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _falhou
                          ? Colors.red.withOpacity(0.15)
                          : primary.withOpacity(0.12),
                      border: Border.all(
                        color: _falhou
                            ? Colors.red.withOpacity(0.5)
                            : primary.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _falhou
                          ? Icons.lock_rounded
                          : Icons.fingerprint_rounded,
                      size: 44,
                      color: _falhou ? Colors.red.shade400 : primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Calculadora Penal',
                    style: GoogleFonts.cinzel(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: const Color(0xFFF0D488),
                      letterSpacing: 1.2,
                    )),
                  const SizedBox(height: 10),
                  Text(
                    _falhou
                        ? 'Autenticação falhou.\nTente novamente.'
                        : 'Autentique-se para continuar.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14, height: 1.5,
                      color: _falhou
                          ? Colors.red.shade300
                          : const Color(0x9EE8DEC4),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Botão de autenticar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _autenticando ? null : _autenticar,
                      icon: _autenticando
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _falhou
                                  ? Icons.refresh_rounded
                                  : Icons.fingerprint_rounded,
                              size: 20),
                      label: Text(
                        _autenticando
                            ? 'Aguardando...'
                            : _falhou
                                ? 'Tentar novamente'
                                : 'Desbloquear',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: const Color(0xFF050A18),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
