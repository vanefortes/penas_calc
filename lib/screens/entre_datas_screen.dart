import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/calculo.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class EntreDatasScreen extends StatefulWidget {
  const EntreDatasScreen({super.key});

  @override
  State<EntreDatasScreen> createState() => _EntreDatasScreenState();
}

class _EntreDatasScreenState extends State<EntreDatasScreen> {
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _progressao = false;
  ResultadoEntreDatas? _resultado;
  String? _erro;

  String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(d);
  String _fmtDateLong(DateTime d) =>
      DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(d);
  String _fmtNum(int n) =>
      NumberFormat.decimalPattern('pt_BR').format(n);

  Future<void> _selecionarData(bool isInicio) async {
    final initial = isInicio
        ? (_dataInicio ?? DateTime.now())
        : (_dataFim ??
            (_dataInicio ?? DateTime.now())
                .add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      locale: const Locale('pt', 'BR'),
      helpText: isInicio ? 'Data inicial' : 'Data final',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
        _erro = null;
      });
    }
  }

  void _calcular() {
    setState(() => _erro = null);
    if (_dataInicio == null || _dataFim == null) {
      setState(() => _erro = 'Informe as duas datas.');
      return;
    }
    if (!_dataFim!.isAfter(_dataInicio!)) {
      setState(() =>
          _erro = 'A data final deve ser posterior à data inicial.');
      return;
    }
    final res = CalculoEngine.calcularEntreDatas(
        dataInicio: _dataInicio!, dataFim: _dataFim!);
    setState(() => _resultado = res);

    context.read<AppState>().addHistorico(HistoricoItem(
          id: DateTime.now().toIso8601String(),
          timestamp: DateTime.now(),
          tipo: 'Entre datas',
          entrada:
              '${_fmtDate(_dataInicio!)} → ${_fmtDate(_dataFim!)}',
          saida:
              '${res.anos}a ${res.meses}m ${res.dias}d (${_fmtNum(res.totalDias)} dias)',
          modo: 'Calendário real',
          progressao: _progressao,
        ));
  }

  void _limpar() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _progressao = false;
      _resultado = null;
      _erro = null;
    });
  }

  String _textoParaCopiar() {
    if (_resultado == null) return '';
    return 'Calculadora de Penas — Período entre datas\n'
        'De: ${_fmtDateLong(_dataInicio!)}\n'
        'Até: ${_fmtDateLong(_dataFim!)}\n'
        'Anos: ${_resultado!.anos}\n'
        'Meses: ${_resultado!.meses}\n'
        'Dias restantes: ${_resultado!.dias}\n'
        'Total em dias: ${_fmtNum(_resultado!.totalDias)}\n'
        '${_progressao ? "Progressão de regime: dias exatos\n" : ""}'
        'Data do cálculo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calcule o período exato entre duas datas.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _buildDateCard(
                    'Data inicial', _dataInicio, true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded,
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color,
                  size: 18),
            ),
            Expanded(
                child:
                    _buildDateCard('Data final', _dataFim, false)),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () =>
                setState(() => _progressao = !_progressao),
            child: Row(children: [
              Checkbox(
                value: _progressao,
                onChanged: (v) =>
                    setState(() => _progressao = v ?? false),
                activeColor: AppTheme.accentColor(context),
              ),
              Expanded(
                child: Text(
                  'Progressão de regime (dias exatos)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ]),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(Icons.error_outline_rounded,
                    size: 16,
                    color: AppTheme.dangerColor(context)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_erro!,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color:
                                AppTheme.dangerColor(context)))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _calcular,
                icon: const Icon(Icons.calculate_rounded,
                    size: 18),
                label: const Text('Calcular período'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _limpar,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Limpar'),
            ),
          ]),
          if (_resultado != null) ...[
            const SizedBox(height: 20),
            _buildResultados(),
          ],
        ],
      ),
    );
  }

  Widget _buildDateCard(
      String label, DateTime? date, bool isInicio) {
    return GestureDetector(
      onTap: () => _selecionarData(isInicio),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ??
                Colors.grey.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.color)),
            const SizedBox(height: 4),
            date != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtDate(date),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.color,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE', 'pt_BR').format(date),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.color),
                      ),
                    ],
                  )
                : Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14,
                        color: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.color),
                    const SizedBox(width: 6),
                    Text('Selecionar',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.color)),
                  ]),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados() {
    final r = _resultado!;
    final formula =
        'De: ${_fmtDate(_dataInicio!)} → ${_fmtDate(_dataFim!)}\n'
        'Decomposição: ${r.anos}a ${r.meses}m ${r.dias}d = ${_fmtNum(r.totalDias)} dias corridos'
        '${_progressao ? '\nProgressão de regime: cálculo em dias exatos.' : ''}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).dividerTheme.color ??
                Colors.grey.withOpacity(0.2),
            width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('Período calculado',
                    style:
                        Theme.of(context).textTheme.titleMedium),
                if (_progressao) ...[
                  const SizedBox(width: 8),
                  const ProgressaoBadge(),
                ],
              ]),
              CopyButton(textToCopy: _textoParaCopiar()),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ResultCard(
                label: 'Anos', value: '${r.anos}')),
            const SizedBox(width: 8),
            Expanded(child: ResultCard(
                label: 'Meses', value: '${r.meses}')),
            const SizedBox(width: 8),
            Expanded(child: ResultCard(
                label: 'Dias restantes', value: '${r.dias}')),
          ]),
          const SizedBox(height: 8),
          ResultCard(
            label: 'Total em dias corridos',
            value: '${_fmtNum(r.totalDias)} dias',
            highlight: true,
          ),
          const SizedBox(height: 12),
          FormulaBox(text: _resultado!.detalhes),
          const SizedBox(height: 10),
          const AvisoLegal(),
        ],
      ),
    );
  }
}
