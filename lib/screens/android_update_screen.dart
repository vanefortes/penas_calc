// lib/screens/android_update_screen.dart
//
// Exibida no Android quando o Play Core encontra uma atualização
// OPCIONAL (flexível) disponível. Ao tocar em "Atualizar agora", o
// download roda em segundo plano pela própria Play Store; quando
// termina, o app reinicia sozinho já na versão nova. Se o usuário
// preferir, pode seguir usando o app normalmente sem atualizar agora.
//
// Atualizações obrigatórias (prioridade alta) não passam por esta tela:
// nesses casos o Google já assume com sua própria UI nativa em tela
// cheia (ver AndroidUpdateService.verificar).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/android_update_service.dart';
import 'splash_screen.dart' show CpColors;

class AndroidUpdateScreen extends StatefulWidget {
  /// Chamado quando o usuário escolhe seguir sem atualizar agora.
  final VoidCallback onContinuar;

  const AndroidUpdateScreen({super.key, required this.onContinuar});

  @override
  State<AndroidUpdateScreen> createState() => _AndroidUpdateScreenState();
}

class _AndroidUpdateScreenState extends State<AndroidUpdateScreen> {
  bool _baixando = false;
  String? _erro;

  Future<void> _atualizar() async {
    setState(() {
      _baixando = true;
      _erro = null;
    });

    final sucesso = await AndroidUpdateService.iniciarFlexivel();

    // Se der certo, o app reinicia sozinho para instalar — não sobra
    // ninguém aqui para atualizar o estado. Só tratamos o caso de falha.
    if (!mounted) return;
    if (!sucesso) {
      setState(() {
        _baixando = false;
        _erro = 'Não foi possível baixar a atualização agora. '
            'Tente novamente mais tarde.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CpColors.navyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    CpColors.goldBright.withOpacity(0.22),
                    CpColors.goldDeep.withOpacity(0.04),
                  ]),
                  border: Border.all(color: CpColors.goldDeep, width: 1),
                ),
                child: const Icon(Icons.system_update_alt_rounded,
                    color: CpColors.goldBright, size: 40),
              ),
              const SizedBox(height: 26),
              Text(
                'NOVA ATUALIZAÇÃO DISPONÍVEL',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: CpColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Uma nova versão do Calculadora Penal já está pronta para '
                'baixar direto pela Play Store.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: CpColors.textDim,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 20),
                Text(_erro!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: const Color(0xFFE08585), fontSize: 12)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _baixando ? null : _atualizar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CpColors.goldBright,
                    foregroundColor: CpColors.navyDeep,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _baixando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: CpColors.navyDeep),
                        )
                      : Text('ATUALIZAR AGORA',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _baixando ? null : widget.onContinuar,
                child: Text('Agora não, continuar',
                    style: GoogleFonts.inter(
                        color: CpColors.textFaint, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
