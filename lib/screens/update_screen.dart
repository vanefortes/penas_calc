// lib/screens/update_screen.dart
//
// Exibida quando há uma nova versão do app disponível na loja.
// Se a atualização for opcional, o usuário pode tocar em "Agora não,
// continuar" e seguir usando o app normalmente. Se for obrigatória
// (versão instalada abaixo da mínima aceita), o botão de continuar não
// é exibido.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import 'splash_screen.dart' show CpColors;

class UpdateScreen extends StatefulWidget {
  final UpdateInfo info;

  /// Chamado quando o usuário escolhe seguir sem atualizar.
  /// Deixe null para não exibir essa opção (atualização obrigatória).
  final VoidCallback? onContinuar;

  const UpdateScreen({super.key, required this.info, this.onContinuar});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _abrindoLoja = false;
  String? _erro;

  Future<void> _abrirLoja() async {
    setState(() {
      _abrindoLoja = true;
      _erro = null;
    });
    try {
      final uri = Uri.parse(widget.info.urlLoja);
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu && mounted) {
        setState(() => _erro = 'Não foi possível abrir a loja de aplicativos.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível abrir a loja de aplicativos.');
      }
    } finally {
      if (mounted) setState(() => _abrindoLoja = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final podeContinuar = !info.obrigatoria && widget.onContinuar != null;

    return WillPopScope(
      // Se a atualização for obrigatória, bloqueia o botão "voltar" do
      // Android para o usuário não escapar da tela sem atualizar.
      onWillPop: () async => podeContinuar,
      child: Scaffold(
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
                  info.obrigatoria
                      ? 'É necessário atualizar o app para continuar usando.'
                      : 'Uma nova versão do Calculadora Penal já está disponível.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: CpColors.textDim,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: CpColors.navy,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CpColors.goldDeep.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('v${info.versaoAtual}',
                          style: GoogleFonts.inter(
                              color: CpColors.textFaint, fontSize: 13)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 14, color: CpColors.goldDeep),
                      ),
                      Text('v${info.versaoNova}',
                          style: GoogleFonts.inter(
                              color: CpColors.goldBright,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (info.notas.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CpColors.navy.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CpColors.goldDeep.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('O que há de novo',
                            style: GoogleFonts.inter(
                                color: CpColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(info.notas,
                            style: GoogleFonts.inter(
                                color: CpColors.textDim,
                                fontSize: 13,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Text(_erro!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: const Color(0xFFE08585), fontSize: 12)),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _abrindoLoja ? null : _abrirLoja,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CpColors.goldBright,
                      foregroundColor: CpColors.navyDeep,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _abrindoLoja
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
                if (podeContinuar) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: widget.onContinuar,
                    child: Text('Agora não, continuar',
                        style: GoogleFonts.inter(
                            color: CpColors.textFaint, fontSize: 13)),
                  ),
                ] else if (info.obrigatoria) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Esta atualização é obrigatória para continuar usando o app.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: CpColors.textFaint, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
