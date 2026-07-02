import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../services/subscription_service.dart';
import '../models/calculo.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_perfil.dart';
import 'paywall_screen.dart';

class ConfiguracaoScreen extends StatelessWidget {
  const ConfiguracaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───── NOVO: Conta / perfil do usuário ─────
          _sectionTitle(context, 'Conta'),
          const SizedBox(height: 10),
          _PerfilTile(
            nome: state.usuarioNome,
            oab: state.usuarioOab,
            onTap: () => Navigator.of(context).pushNamed('/dados-cadastrais'),
          ),
          const SizedBox(height: 24),

          _sectionTitle(context, 'Assinatura'),
          const SizedBox(height: 10),
          const _AssinaturaTile(),
          const SizedBox(height: 24),

          _sectionTitle(context, 'Template visual'),
          const SizedBox(height: 10),
          _TemplateSelector(selected: state.template),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Modo de cálculo padrão'),
          const SizedBox(height: 10),
          ...ModoCalculo.values.map(
            (m) => _ModoTile(
                modo: m, selected: state.modoCalculo == m),
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Aparência'),
          const SizedBox(height: 10),
          _ThemeTile(
            label: 'Sistema',
            icon: Icons.phone_android_rounded,
            mode: ThemeMode.system,
            selected: state.themeMode == ThemeMode.system,
          ),
          const SizedBox(height: 6),
          _ThemeTile(
            label: 'Tema claro',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            selected: state.themeMode == ThemeMode.light,
          ),
          const SizedBox(height: 6),
          _ThemeTile(
            label: 'Tema escuro',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
            selected: state.themeMode == ThemeMode.dark,
          ),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Sobre'),
          const SizedBox(height: 10),
          _infoCard(context),
          const SizedBox(height: 24),
          _sectionTitle(context, 'Zona de risco'),
          const SizedBox(height: 10),
          _ExcluirContaTile(),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: Theme.of(context)
                .textTheme
                .labelSmall
                ?.color,
          ),
        ),
      );

  Widget _infoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ??
              Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.gavel_rounded,
                size: 20,
                color: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.color),
            const SizedBox(width: 10),
            Text('Calculadora de Penas',
                style:
                    Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 6),
          Text('Versão 1.0.0 • Uso criminalístico',
              style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 24),
          Text(
            'Modos disponíveis:\n'
            '• Padrão: 1 ano = 365 dias · 1 mês = 30 dias\n'
            '• Calendário real: meses civis + bissextos\n'
            '• Jurídico: 1 mês = 365/12 dias',
            style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.7,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.warningBg(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Resultados informativos — confirmar com legislação aplicável e documentação do processo.',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: AppTheme.warningColor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOVO — Tile de perfil (Conta) que leva para DadosCadastraisScreen
// ---------------------------------------------------------------------------

class _PerfilTile extends StatelessWidget {
  final String nome;
  final String oab;
  final VoidCallback onTap;
  const _PerfilTile({
    required this.nome,
    required this.oab,
    required this.onTap,
  });

  String _iniciais(String n) {
    final parts = n.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final preenchido = nome.isNotEmpty;
    final nomeMostrado = preenchido ? nome : 'Adicionar dados cadastrais';
    final subtitulo = preenchido
        ? (oab.isNotEmpty ? 'OAB: $oab' : 'OAB não informada')
        : 'Toque para configurar seu perfil';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ??
                  Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(children: [
            // Avatar
            const AvatarPerfil(size: 44, editavel: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeMostrado,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).textTheme.labelSmall?.color),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seletor de templates visuais
// ---------------------------------------------------------------------------

class _TemplateSelector extends StatelessWidget {
  final AppTemplate selected;
  const _TemplateSelector({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: AppTemplate.values
          .map((t) => _TemplateTile(
              template: t, selected: selected == t))
          .toList(),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final AppTemplate template;
  final bool selected;
  const _TemplateTile(
      {required this.template, required this.selected});

  @override
  Widget build(BuildContext context) {
    final primary = template.corPrimaria;
    final accent = template.corAcento;
    final bg = template.corFundo;

    return GestureDetector(
      onTap: () =>
          context.read<AppState>().setTemplate(template),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? bg : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primary.withOpacity(0.6)
                : Theme.of(context).dividerTheme.color ??
                    Colors.grey.withOpacity(0.2),
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(children: [
          _ColorPreview(
              primary: primary, accent: accent, bg: bg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.nome,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? primary
                        : Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  template.descricao,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: selected
                        ? primary.withOpacity(0.7)
                        : Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded,
                color: primary, size: 22)
          else
            Icon(Icons.radio_button_unchecked_rounded,
                color: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.color,
                size: 22),
        ]),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final Color primary;
  final Color accent;
  final Color bg;
  const _ColorPreview(
      {required this.primary,
      required this.accent,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: primary.withOpacity(0.2), width: 0.5),
      ),
      child: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
          ),
        ),
        Positioned(
          top: 18,
          left: 5,
          right: 5,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          left: 8,
          right: 8,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile de modo de cálculo
// ---------------------------------------------------------------------------

class _ModoTile extends StatelessWidget {
  final ModoCalculo modo;
  final bool selected;
  const _ModoTile({required this.modo, required this.selected});

  @override
  Widget build(BuildContext context) {
    final primary =
        Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () =>
          context.read<AppState>().setModoCalculo(modo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentBg(context)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? primary.withOpacity(0.4)
                : Theme.of(context).dividerTheme.color ??
                    Colors.grey.withOpacity(0.2),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: selected
                ? primary
                : Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modo.nome,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? primary
                            : Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.color)),
                Text(modo.descricao,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: selected
                            ? primary.withOpacity(0.7)
                            : Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile de tema claro/escuro
// ---------------------------------------------------------------------------

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final bool selected;
  const _ThemeTile(
      {required this.label,
      required this.icon,
      required this.mode,
      required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.read<AppState>().setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.surfaceColor(context)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ??
                Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium)),
          if (selected)
            Icon(Icons.check_rounded,
                size: 16,
                color: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.color),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOVO — Tile "Excluir conta e dados" (Zona de risco)
// ---------------------------------------------------------------------------

class _ExcluirContaTile extends StatelessWidget {
  const _ExcluirContaTile();

  Future<void> _confirmarExclusao(BuildContext context) async {
    // Primeira confirmação.
    final primeiraOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta e dados?'),
        content: const Text(
          'Isso vai apagar permanentemente seu perfil, histórico de '
          'cálculos e preferências salvas neste dispositivo, e desconectar '
          'sua conta Google. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (primeiraOk != true || !context.mounted) return;

    // Segunda confirmação (ação destrutiva e irreversível).
    final confirmadoFinal = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tem certeza?'),
        content: const Text(
          'Todos os seus dados serão apagados agora. Não será possível '
          'recuperá-los depois.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400),
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
    if (confirmadoFinal != true || !context.mounted) return;

    await context.read<AppState>().excluirContaEDados();
    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
        '/onboarding', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmarExclusao(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.red.shade400.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          Icon(Icons.delete_forever_rounded,
              size: 18, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Excluir conta e dados',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade400,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: Colors.red.shade400),
        ]),
      ),
    );
  }
}

/// Card de status da assinatura, com atalho para gerenciar (App Store)
/// ou assinar, caso o usuário tenha chegado até aqui sem assinatura ativa
/// (por exemplo, restaurou um trial expirado).
class _AssinaturaTile extends StatefulWidget {
  const _AssinaturaTile();

  @override
  State<_AssinaturaTile> createState() => _AssinaturaTileState();
}

class _AssinaturaTileState extends State<_AssinaturaTile> {
  bool _restaurando = false;

  Future<void> _abrirGerenciamento() async {
    // URL padrão da Apple para a tela de gerenciamento de assinaturas.
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _restaurar() async {
    setState(() => _restaurando = true);
    final ok = await SubscriptionService.instance.restaurar();
    if (!mounted) return;
    setState(() => _restaurando = false);
    if (ok) {
      await context.read<AppState>().atualizarStatusAssinatura();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Assinatura restaurada com sucesso!'
          : 'Nenhuma assinatura ativa encontrada.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded,
                size: 20,
                color: state.isPremium ? primary : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.isPremium ? 'Assinatura Premium ativa' : 'Sem assinatura ativa',
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isPremium)
            OutlinedButton(
              onPressed: _abrirGerenciamento,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: primary.withOpacity(0.4)),
              ),
              child: Text('Gerenciar assinatura', style: GoogleFonts.inter(fontSize: 13.5)),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen(dispensavel: true)),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: primary,
              ),
              child: Text('Assinar agora', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _restaurando ? null : _restaurar,
              child: _restaurando
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Restaurar compra', style: GoogleFonts.inter(fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}
