import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/calculo.dart';
import '../services/app_state.dart';
import '../services/pdf_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

class ProjecaoScreen extends StatefulWidget {
  const ProjecaoScreen({super.key});

  @override
  State<ProjecaoScreen> createState() => _ProjecaoScreenState();
}

class _ProjecaoScreenState extends State<ProjecaoScreen> {
  DateTime? _dataInicio;
  final _anosCtrl = TextEditingController();
  final _mesesCtrl = TextEditingController();
  final _diasCtrl = TextEditingController();
  double _fracao = 1.0;
  bool _progressao = false;
  ResultadoProjecao? _resultado;
  String? _erro;

  static const _fracoes = [
    (valor: 1.0, label: 'Pena total'),
    (valor: 0.16666666666666666, label: '1/6 da pena'),
    (valor: 0.25, label: '1/4 da pena'),
    (valor: 0.3333333333333333, label: '1/3 da pena'),
    (valor: 0.4, label: '2/5 da pena'),
    (valor: 0.5, label: '1/2 da pena'),
    (valor: 0.6, label: '3/5 da pena'),
    (valor: 0.6666666666666666, label: '2/3 da pena'),
  ];

  @override
  void dispose() {
    _anosCtrl.dispose();
    _mesesCtrl.dispose();
    _diasCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(d);
  String _fmtDateLong(DateTime d) =>
      DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(d);
  String _fmtDiaSemana(DateTime d) =>
      DateFormat('EEEE', 'pt_BR').format(d);
  String _fmtNum(double n, {int dec = 0}) =>
      NumberFormat.decimalPattern('pt_BR')
          .format(double.parse(n.toStringAsFixed(dec)));

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar data inicial',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) setState(() => _dataInicio = picked);
  }

  void _calcular() {
    final appState = context.read<AppState>();
    if (!appState.podeCalcular) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen(dispensavel: true)),
      );
      return;
    }

    setState(() => _erro = null);
    if (_dataInicio == null) {
      setState(() => _erro = 'Informe a data inicial.');
      return;
    }
    final a = int.tryParse(_anosCtrl.text) ?? 0;
    final m = int.tryParse(_mesesCtrl.text) ?? 0;
    final d = int.tryParse(_diasCtrl.text) ?? 0;
    if (a == 0 && m == 0 && d == 0) {
      setState(() => _erro = 'Informe pelo menos um valor de pena.');
      return;
    }
    if (a < 0 || m < 0 || d < 0) {
      setState(() => _erro = 'Valores negativos não são permitidos.');
      return;
    }
    final modo = context.read<AppState>().modoCalculo;
    final fracaoLabel = _fracoes
        .firstWhere((f) => (f.valor - _fracao).abs() < 0.001,
            orElse: () => _fracoes.first)
        .label;
    final res = CalculoEngine.projetarData(
      dataInicio: _dataInicio!,
      anos: a,
      meses: m,
      dias: d,
      modo: modo,
      fracao: _fracao < 1.0 ? _fracao : null,
      nomeFracao: _fracao < 1.0 ? fracaoLabel : null,
    );
    setState(() => _resultado = res);

    context.read<AppState>().addHistorico(HistoricoItem(
          id: DateTime.now().toIso8601String(),
          timestamp: DateTime.now(),
          tipo: 'Projeção',
          entrada: '${_fmtDate(_dataInicio!)} + ${a}a ${m}m ${d}d',
          saida:
              'Término: ${_fmtDate(res.dataFim)}${res.dataFracao != null ? " · Fração: ${_fmtDate(res.dataFracao!)}" : ""}',
          modo: modo.nome,
          progressao: _progressao,
        ));
    appState.registrarCalculoGratis();
  }

  void _limpar() {
    _anosCtrl.clear();
    _mesesCtrl.clear();
    _diasCtrl.clear();
    setState(() {
      _dataInicio = null;
      _fracao = 1.0;
      _progressao = false;
      _resultado = null;
      _erro = null;
    });
  }

  String _textoParaCopiar() {
    if (_resultado == null) return '';
    final modo = context.read<AppState>().modoCalculo;
    return 'Calculadora de Penas — Projeção de Data\n'
        'Início: ${_fmtDate(_dataInicio!)}\n'
        'Pena: ${_anosCtrl.text}a ${_mesesCtrl.text}m ${_diasCtrl.text}d\n'
        'Término: ${_fmtDateLong(_resultado!.dataFim)}\n'
        '(${_fmtDiaSemana(_resultado!.dataFim)})\n'
        'Total: ${_fmtNum(_resultado!.periodo.totalDias)} dias\n'
        '${_resultado!.dataFracao != null ? "Fração (${_resultado!.nomeFracao}): ${_fmtDate(_resultado!.dataFracao!)}\n" : ""}'
        'Modo: ${modo.nome}\n'
        '${_progressao ? "Progressão de regime: cálculo em dias exatos\n" : ""}'
        'Data do cálculo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
  }

  Future<void> _gerarPdf() async {
    if (_resultado == null || _dataInicio == null) return;
    final state = context.read<AppState>();
    final r = _resultado!;
    await PdfProjecao.gerar(
      dataInicio:   _fmtDate(_dataInicio!),
      pena:         '${_anosCtrl.text}a ${_mesesCtrl.text}m ${_diasCtrl.text}d',
      dataTermino:  _fmtDateLong(r.dataFim),
      diaSemana:    _fmtDiaSemana(r.dataFim),
      totalDias:    _fmtNum(r.periodo.totalDias),
      fracao:       r.nomeFracao ?? '',
      dataFracao:   r.dataFracao != null ? _fmtDate(r.dataFracao!) : '',
      detalhes:     r.detalhes,
      modoCalculo:  state.modoCalculo.nome,
      nome:         state.usuarioNome,
      oab:          state.usuarioOab,
      foto:         state.usuarioFoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informe a data inicial e o período de pena para calcular a data de término.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _buildDataSelector(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
              controller: _anosCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Anos de pena'),
              onChanged: (_) => setState(() => _erro = null),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _mesesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Meses de pena'),
              onChanged: (_) => setState(() => _erro = null),
            )),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _diasCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dias de pena'),
              onChanged: (_) => setState(() => _erro = null),
            )),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<double>(
            value: _fracao,
            items: _fracoes
                .map((f) => DropdownMenuItem(
                    value: f.valor, child: Text(f.label)))
                .toList(),
            onChanged: (v) => setState(() => _fracao = v ?? 1.0),
            decoration: const InputDecoration(
              labelText: 'Fração para progressão',
              prefixIcon:
                  Icon(Icons.gavel_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _progressao = !_progressao),
            child: Row(children: [
              Checkbox(
                value: _progressao,
                onChanged: (v) =>
                    setState(() => _progressao = v ?? false),
                activeColor: AppTheme.accentColor(context),
              ),
              Expanded(
                child: Text(
                  'Cálculo de progressão de regime (dias exatos)',
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
                            color: AppTheme.dangerColor(context)))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _calcular,
                icon: const Icon(Icons.event_available_rounded,
                    size: 18),
                label: const Text('Calcular data final'),
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

  Widget _buildDataSelector() {
    return GestureDetector(
      onTap: _selecionarData,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _dataInicio != null
                ? AppTheme.accentColor(context).withOpacity(0.5)
                : Theme.of(context).dividerTheme.color ??
                    Colors.grey.withOpacity(0.3),
            width: _dataInicio != null ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 18,
              color: _dataInicio != null
                  ? AppTheme.accentColor(context)
                  : Theme.of(context).textTheme.labelSmall?.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data inicial (início do cumprimento)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dataInicio != null
                      ? _fmtDateLong(_dataInicio!)
                      : 'Toque para selecionar',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: _dataInicio != null
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: _dataInicio != null
                        ? Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.color
                        : Theme.of(context)
                            .textTheme
                            .labelSmall
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
    );
  }

  Widget _buildResultados() {
    final r = _resultado!;
    final modo = context.read<AppState>().modoCalculo;
    final formula =
        'Início: ${_fmtDate(_dataInicio!)}\n'
        'Pena: ${_anosCtrl.text.isEmpty ? "0" : _anosCtrl.text}a '
        '${_mesesCtrl.text.isEmpty ? "0" : _mesesCtrl.text}m '
        '${_diasCtrl.text.isEmpty ? "0" : _diasCtrl.text}d '
        '= ${_fmtNum(r.periodo.totalDias)} dias (${modo.nome})\n'
        'Término: ${_fmtDateLong(r.dataFim)}'
        '${r.dataFracao != null ? "\nFração (${r.nomeFracao}): ${r.diasFracao} dias → ${_fmtDate(r.dataFracao!)}" : ""}'
        '${_progressao ? "\nProgressão de regime: dias exatos." : ""}';

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
              Flexible(
                child: Text('Projeção calculada',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(width: 8),
              CopyButton(textToCopy: _textoParaCopiar()),
              const SizedBox(width: 8),
              PdfButton(onTap: _gerarPdf),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentBg(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color:
                      AppTheme.accentColor(context).withOpacity(0.4),
                  width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.event_available_rounded,
                      size: 14,
                      color: AppTheme.accentColor(context)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'DATA DE TÉRMINO',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: AppTheme.accentColor(context),
                      ),
                    ),
                  ),
                  if (_progressao) ...[
                    const SizedBox(width: 8),
                    const ProgressaoBadge(),
                  ],
                ]),
                const SizedBox(height: 6),
                Text(
                  _fmtDateLong(r.dataFim),
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentColor(context),
                  ),
                ),
                Text(
                  '${_fmtDiaSemana(r.dataFim)} · ${_fmtDate(r.dataFim)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.accentColor(context)
                        .withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (r.dataFracao != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoBg(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.infoColor(context)
                        .withOpacity(0.4),
                    width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FRAÇÃO · ${r.nomeFracao?.toUpperCase()}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.infoColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtDateLong(r.dataFracao!),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.infoColor(context),
                    ),
                  ),
                  Text(
                    '${_fmtDiaSemana(r.dataFracao!)} · ${_fmtDate(r.dataFracao!)} · ${r.diasFracao} dias',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.infoColor(context)
                          .withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ResultCard(
                label: 'Total (dias)',
                value: _fmtNum(r.periodo.totalDias))),
            const SizedBox(width: 8),
            Expanded(child: ResultCard(
                label: 'Anos', value: '${r.periodo.anos}')),
            const SizedBox(width: 8),
            Expanded(child: ResultCard(
                label: 'Meses + Dias',
                value: '${r.periodo.meses}m ${r.periodo.dias}d')),
          ]),
          const SizedBox(height: 12),
          FormulaBox(text: _resultado!.detalhes),
          const SizedBox(height: 10),
          const AvisoLegal(),
        ],
      ),
    );
  }
}
