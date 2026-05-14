import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../models/calculo.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hist = state.historico;

    return hist.isEmpty
        ? const EmptyState(
            message:
                'Nenhum cálculo realizado ainda.\nComece convertendo um período.',
            icon: Icons.history_rounded,
          )
        : Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${hist.length} cálculo${hist.length != 1 ? "s" : ""}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _confirmarLimpar(context, state),
                    icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16),
                    label: const Text('Limpar tudo'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          AppTheme.dangerColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: hist.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _HistItem(item: hist[i]),
              ),
            ),
          ]);
  }

  Future<void> _confirmarLimpar(
      BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar histórico'),
        content: const Text(
            'Deseja apagar todos os cálculos do histórico?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apagar tudo')),
        ],
      ),
    );
    if (ok == true) state.limparHistorico();
  }
}

class _HistItem extends StatelessWidget {
  final HistoricoItem item;
  const _HistItem({required this.item});

  Color _tipoColor(BuildContext context) {
    switch (item.tipo) {
      case 'Projeção':
        return AppTheme.accentColor(context);
      case 'Entre datas':
        return AppTheme.infoColor(context);
      default:
        return Theme.of(context).textTheme.labelSmall?.color ??
            Colors.grey;
    }
  }

  Color _tipoBg(BuildContext context) {
    switch (item.tipo) {
      case 'Projeção':
        return AppTheme.accentBg(context);
      case 'Entre datas':
        return AppTheme.infoBg(context);
      default:
        return AppTheme.surfaceColor(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ??
              Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _tipoBg(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.tipo,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _tipoColor(context),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.entrada,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.color)),
                const SizedBox(height: 2),
                Text(item.saida,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color)),
                const SizedBox(height: 3),
                Row(children: [
                  Text(item.modo,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.color)),
                  if (item.progressao) ...[
                    const SizedBox(width: 6),
                    const ProgressaoBadge(),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(item.timestampFormatado,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color)),
        ],
      ),
    );
  }
}
