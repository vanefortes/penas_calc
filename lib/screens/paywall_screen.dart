// lib/screens/paywall_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/app_state.dart';
import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  /// Se true, mostra um botão de fechar (uso não bloqueante).
  /// Se false, o paywall é a única saída possível (bloqueia o app).
  final bool dispensavel;

  const PaywallScreen({super.key, this.dispensavel = false});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _carregandoOfferings = true;
  bool _comprando = false;
  bool _restaurando = false;
  String? _erro;
  Package? _selecionado;

  @override
  void initState() {
    super.initState();
    _carregarOfferings();
  }

  Future<void> _carregarOfferings() async {
    final offering = await SubscriptionService.instance.getCurrentOffering();
    if (!mounted) return;
    setState(() {
      _offering = offering;
      _carregandoOfferings = false;
      // Pré-seleciona o pacote anual, se existir; senão o primeiro disponível.
      final pacotes = offering?.availablePackages ?? [];
      _selecionado = pacotes.isEmpty
          ? null
          : pacotes.firstWhere(
              (p) => p.packageType == PackageType.annual,
              orElse: () => pacotes.first,
            );
    });
  }

  Future<void> _assinar(Package pacote) async {
    setState(() { _comprando = true; _erro = null; });
    final result = await SubscriptionService.instance.purchase(pacote);
    if (!mounted) return;
    setState(() => _comprando = false);

    if (result.sucesso) {
      await context.read<AppState>().atualizarStatusAssinatura();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } else if (!result.cancelado) {
      setState(() => _erro = result.erro ?? 'Não foi possível concluir a compra. Tente novamente.');
    }
  }

  Future<void> _restaurar() async {
    setState(() { _restaurando = true; _erro = null; });
    final ok = await SubscriptionService.instance.restaurar();
    if (!mounted) return;
    setState(() => _restaurando = false);

    if (ok) {
      await context.read<AppState>().atualizarStatusAssinatura();
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } else {
      setState(() => _erro = 'Nenhuma assinatura ativa encontrada para restaurar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pacotes = _offering?.availablePackages ?? [];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.dispensavel)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close_rounded, color: cs.onSurface.withOpacity(0.5)),
                  ),
                ),
              const SizedBox(height: 8),
              Icon(Icons.gavel_rounded, size: 44, color: cs.primary),
              const SizedBox(height: 20),
              Text(
                'Calculadora Penal Pro',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  fontSize: 24, fontWeight: FontWeight.w700, color: cs.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Assine para ter cálculos ilimitados, histórico completo e exportação em PDF.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14.5, color: cs.onSurface.withOpacity(0.65), height: 1.5),
              ),
              const SizedBox(height: 24),
              const _Beneficio(icone: Icons.calculate_rounded, texto: 'Conversão de penas com múltiplos critérios (Padrão, TJSP, STJ)'),
              const _Beneficio(icone: Icons.event_available_rounded, texto: 'Projeção de progressão de regime'),
              const _Beneficio(icone: Icons.history_rounded, texto: 'Histórico completo de cálculos'),
              const _Beneficio(icone: Icons.picture_as_pdf_rounded, texto: 'Exportação de relatórios em PDF'),
              const SizedBox(height: 24),

              if (_carregandoOfferings)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
              else if (pacotes.isEmpty)
                Text(
                  'Não foi possível carregar os planos agora. Verifique sua conexão e tente novamente.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.red.shade400),
                )
              else ...[
                ...pacotes.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanoCard(
                    pacote: p,
                    selecionado: _selecionado?.identifier == p.identifier,
                    onTap: () => setState(() => _selecionado = p),
                  ),
                )),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_comprando || _selecionado == null)
                        ? null
                        : () => _assinar(_selecionado!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _comprando
                        ? SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                        : Text('Assinar agora',
                            style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],

              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.red.shade400)),
              ],

              const SizedBox(height: 14),
              TextButton(
                onPressed: _restaurando ? null : _restaurar,
                child: _restaurando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Restaurar compra',
                        style: GoogleFonts.inter(fontSize: 13.5, color: cs.onSurface.withOpacity(0.6))),
              ),

              const SizedBox(height: 6),
              Text(
                'A assinatura é renovada automaticamente ao fim de cada período, salvo cancelamento pelo App Store, em Ajustes → [seu nome] → Assinaturas. Ao assinar, você concorda com os Termos de Uso e a Política de Privacidade.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10.5, color: cs.onSurface.withOpacity(0.45), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card selecionável de um plano de assinatura (semanal/mensal/anual).
class _PlanoCard extends StatelessWidget {
  final Package pacote;
  final bool selecionado;
  final VoidCallback onTap;
  const _PlanoCard({required this.pacote, required this.selecionado, required this.onTap});

  String get _rotulo {
    switch (pacote.packageType) {
      case PackageType.weekly:  return 'Semanal';
      case PackageType.monthly: return 'Mensal';
      case PackageType.annual:  return 'Anual';
      default: return pacote.storeProduct.title;
    }
  }

  String? get _selo {
    if (pacote.packageType == PackageType.annual) return 'Melhor custo-benefício';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado ? cs.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? cs.primary : cs.primary.withOpacity(0.2),
            width: selecionado ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selecionado ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selecionado ? cs.primary : cs.onSurface.withOpacity(0.35),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(_rotulo,
                      style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600)),
                    if (_selo != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_selo!,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: cs.onPrimary)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            Text(
              pacote.storeProduct.priceString,
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Beneficio extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _Beneficio({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 19, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
              style: GoogleFonts.inter(fontSize: 13.5, color: cs.onSurface.withOpacity(0.8), height: 1.3)),
          ),
        ],
      ),
    );
  }
}
