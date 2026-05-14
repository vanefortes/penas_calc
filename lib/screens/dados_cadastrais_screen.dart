// lib/screens/dados_cadastrais_screen.dart
// Tela de visualização dos dados cadastrais.
// A edição é feita na EditarCadastroScreen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/avatar_perfil.dart';

class DadosCadastraisScreen extends StatelessWidget {
  const DadosCadastraisScreen({super.key});

  Future<void> _confirmarReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetar primeiro acesso?'),
        content: const Text(
          'Os dados cadastrais serão apagados deste dispositivo e o '
          'onboarding será exibido novamente na próxima abertura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AppState>().resetarPrimeiroAcesso();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);
  }

  void _abrirEdicao(BuildContext context) {
    Navigator.of(context).pushNamed('/editar-cadastro');
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final primary = Theme.of(context).colorScheme.primary;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          const Icon(Icons.badge_rounded, size: 20),
          const SizedBox(width: 10),
          const Text('Dados cadastrais'),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _abrirEdicao(context),
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Editar'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + nome destaque
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(children: [
                // Avatar com foto de perfil editável
                const AvatarPerfil(size: 56, editavel: false),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    state.usuarioNome.isNotEmpty ? state.usuarioNome : 'Nome não informado',
                    style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: state.usuarioNome.isNotEmpty
                          ? Theme.of(context).textTheme.titleLarge?.color
                          : Theme.of(context).textTheme.labelSmall?.color,
                    ),
                  ),
                  if (state.usuarioOab.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('OAB ${state.usuarioOab}',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
                    ),
                  ],
                ])),
              ]),
            ),

            _sectionTitle(context, 'Identificação profissional'),
            const SizedBox(height: 10),
            _InfoCard(children: [
              _InfoRow(
                icon: Icons.person_rounded,
                label: 'Nome do(a) advogado(a)',
                value: state.usuarioNome,
                emptyHint: 'Não informado',
              ),
              _divider(context),
              _InfoRow(
                icon: Icons.shield_rounded,
                label: 'OAB / UF',
                value: state.usuarioOab,
                emptyHint: 'Não informado',
              ),
              _divider(context),
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'E-mail',
                value: state.usuarioEmail,
                emptyHint: 'Não informado',
              ),
            ]),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Segurança'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Row(children: [
                Icon(Icons.fingerprint_rounded, size: 22,
                  color: Theme.of(context).textTheme.titleMedium?.color),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Proteção biométrica',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color)),
                  const SizedBox(height: 2),
                  Text('Face ID / Touch ID ao abrir',
                    style: GoogleFonts.inter(fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
                ])),
                // Badge de status (somente leitura)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: state.biometriaAtiva
                        ? Colors.green.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      state.biometriaAtiva ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 13,
                      color: state.biometriaAtiva ? Colors.green.shade600 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.biometriaAtiva ? 'Ativa' : 'Inativa',
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: state.biometriaAtiva ? Colors.green.shade600 : Colors.grey,
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            _sectionTitle(context, 'Zona de risco'),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _confirmarReset(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300.withOpacity(0.5), width: 0.8),
                ),
                child: Row(children: [
                  Icon(Icons.restart_alt_rounded, size: 22, color: Colors.red.shade400),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Resetar primeiro acesso',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.red.shade400)),
                    const SizedBox(height: 2),
                    Text('Apaga os dados cadastrais e exibe o onboarding novamente.',
                      style: GoogleFonts.inter(fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: Colors.red.shade400),
                ]),
              ),
            ),
          ],
        ),
      )),
          // Botão fixo no rodapé
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(
                color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
                width: 0.5,
              )),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _abrirEdicao(context),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar dados cadastrais'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _divider(BuildContext context) => Divider(
    height: 1, thickness: 0.5,
    color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.15),
  );

  Widget _sectionTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(title.toUpperCase(),
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 0.7, color: Theme.of(context).textTheme.labelSmall?.color)),
  );
}

// ── Components ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(context).dividerTheme.color ?? Colors.grey.withOpacity(0.2),
        width: 0.5,
      ),
    ),
    child: Column(children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value, emptyHint;
  const _InfoRow({
    required this.icon, required this.label,
    required this.value, required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).textTheme.labelSmall?.color
        ?? Colors.grey;
    final fg  = Theme.of(context).textTheme.titleMedium?.color
        ?? Theme.of(context).colorScheme.onSurface;
    final isEmpty = value.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(children: [
        Icon(icon, size: 18, color: dim),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: dim)),
          const SizedBox(height: 3),
          Text(
            isEmpty ? emptyHint : value,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isEmpty ? dim.withOpacity(0.5) : fg,
              fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ])),
      ]),
    );
  }
}
