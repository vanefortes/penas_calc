import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/calculo.dart';
import '../services/app_state.dart';
import '../services/pdf_service.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

enum InputMode { amd, totalDias, totalMeses }

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  InputMode _inputMode = InputMode.amd;
  final _anosCtrl = TextEditingController();
  final _mesesCtrl = TextEditingController();
  final _diasCtrl = TextEditingController();
  final _totalDiasCtrl = TextEditingController();
  final _totalMesesCtrl = TextEditingController();
  int _decimais = 2;
  String _arredondamento = 'none';
  PeriodoDecomposto? _resultado;
  String? _erro;
  String _formula = '';

  @override
  void dispose() {
    _anosCtrl.dispose();
    _mesesCtrl.dispose();
    _diasCtrl.dispose();
    _totalDiasCtrl.dispose();
    _totalMesesCtrl.dispose();
    super.dispose();
  }

  String _fmt(double n, {int dec = 0}) =>
      NumberFormat.decimalPattern('pt_BR')
          .format(double.parse(n.toStringAsFixed(dec)));

  double _applyRound(double val, int dec) {
    final factor = _pow10(dec);
    if (_arredondamento == 'up') {
      return (val * factor).ceilToDouble() / factor;
    }
    if (_arredondamento == 'down') {
      return (val * factor).floorToDouble() / factor;
    }
    return double.parse(val.toStringAsFixed(dec));
  }

  double _pow10(int e) {
    double r = 1;
    for (int i = 0; i < e; i++) {
      r *= 10;
    }
    return r;
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
    final modo = context.read<AppState>().modoCalculo;
    final dpm = modo.diasPorMes;
    final dpa = modo.diasPorAno;
    double totalDias = 0;

    if (_inputMode == InputMode.amd) {
      final a = double.tryParse(_anosCtrl.text) ?? 0;
      final m = double.tryParse(_mesesCtrl.text) ?? 0;
      final d = double.tryParse(_diasCtrl.text) ?? 0;
      if (a < 0 || m < 0 || d < 0) {
        setState(() => _erro = 'Valores negativos não são permitidos.');
        return;
      }
      if (a == 0 && m == 0 && d == 0) {
        setState(() => _erro = 'Informe pelo menos um valor.');
        return;
      }
      totalDias = CalculoEngine.calcTotalDias(
          anos: a.toInt(), meses: m.toInt(), dias: d.toInt(),
          modo: modo, dataBase: DateTime.now());
    } else if (_inputMode == InputMode.totalDias) {
      totalDias = double.tryParse(_totalDiasCtrl.text) ?? 0;
      if (totalDias <= 0) {
        setState(() => _erro = 'Informe o total em dias.');
        return;
      }
    } else {
      final tm = double.tryParse(_totalMesesCtrl.text) ?? 0;
      if (tm <= 0) {
        setState(() => _erro = 'Informe o total em meses.');
        return;
      }
      totalDias = tm * dpm;
    }

    final dec = _inputMode == InputMode.totalDias ? _decimais : 2;
    final totalMeses = _applyRound(totalDias / dpm, dec);
    final totalAnos = _applyRound(totalDias / dpa, dec);
    final anosInt = (totalDias / dpa).floor();
    final restDias = totalDias - anosInt * dpa;
    final mesesInt = (restDias / dpm).floor();
    final diasInt = (restDias - mesesInt * dpm).round();

    final res = PeriodoDecomposto(
      anos: anosInt,
      meses: mesesInt,
      dias: diasInt,
      totalDias: totalDias,
      totalMeses: totalMeses,
      totalAnos: totalAnos,
    );

    setState(() {
      _resultado = res;
      _formula =
          'Modo ${modo.nome}: 1 ano = ${_fmt(dpa)} dias · 1 mês = ${_fmt(dpm, dec: 2)} dias\n'
          'Total: ${_fmt(totalDias)} dias → ${anosInt}a ${mesesInt}m ${diasInt}d';
    });

    final entradaTxt = _inputMode == InputMode.amd
        ? '${_anosCtrl.text.isEmpty ? "0" : _anosCtrl.text}a '
            '${_mesesCtrl.text.isEmpty ? "0" : _mesesCtrl.text}m '
            '${_diasCtrl.text.isEmpty ? "0" : _diasCtrl.text}d'
        : _inputMode == InputMode.totalDias
            ? '${_totalDiasCtrl.text} dias totais'
            : '${_totalMesesCtrl.text} meses totais';

    context.read<AppState>().addHistorico(HistoricoItem(
          id: DateTime.now().toIso8601String(),
          timestamp: DateTime.now(),
          tipo: 'Conversão',
          entrada: entradaTxt,
          saida:
              '${anosInt}a ${mesesInt}m ${diasInt}d (${_fmt(totalDias)} dias)',
          modo: modo.nome,
        ));
    appState.registrarCalculoGratis();
  }

  Future<void> _gerarPdf() async {
    if (_resultado == null) return;
    final state = context.read<AppState>();
    await PdfConverter.gerar(
      anos:        '${_resultado!.anos}',
      meses:       '${_resultado!.meses}',
      dias:        '${_resultado!.dias}',
      totalDias:   _fmt(_resultado!.totalDias),
      totalMeses:  _fmt(_resultado!.totalMeses, dec: _decimais),
      totalAnos:   _fmt(_resultado!.totalAnos,  dec: _decimais),
      formula:     _formula,
      modoCalculo: state.modoCalculo.nome,
      nome:        state.usuarioNome,
      oab:         state.usuarioOab,
      foto:        state.usuarioFoto,
    );
  }

  void _limpar() {
    for (final c in [
      _anosCtrl,
      _mesesCtrl,
      _diasCtrl,
      _totalDiasCtrl,
      _totalMesesCtrl
    ]) {
      c.clear();
    }
    setState(() {
      _resultado = null;
      _erro = null;
    });
  }

  String _textoParaCopiar() {
    if (_resultado == null) return '';
    return 'Calculadora de Penas — Conversão\n'
        'Anos: ${_resultado!.anos}\n'
        'Meses: ${_resultado!.meses}\n'
        'Dias: ${_resultado!.dias}\n'
        'Total em dias: ${_fmt(_resultado!.totalDias)}\n'
        'Total em meses: ${_fmt(_resultado!.totalMeses, dec: _decimais)}\n'
        'Total em anos: ${_fmt(_resultado!.totalAnos, dec: _decimais)}\n'
        'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>().modoCalculo;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModeSelector(),
          const SizedBox(height: 16),
          _buildInputFields(),
          if (_erro != null) ...[
            const SizedBox(height: 8),
            _buildErro(_erro!),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _calcular,
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text('Converter'),
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

  Widget _buildModeSelector() => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ModoChip(
            label: 'Anos + Meses + Dias',
            selected: _inputMode == InputMode.amd,
            onTap: () => setState(() {
              _inputMode = InputMode.amd;
              _resultado = null;
            }),
          ),
          ModoChip(
            label: 'Total em dias',
            selected: _inputMode == InputMode.totalDias,
            onTap: () => setState(() {
              _inputMode = InputMode.totalDias;
              _resultado = null;
            }),
          ),
          ModoChip(
            label: 'Total em meses',
            selected: _inputMode == InputMode.totalMeses,
            onTap: () => setState(() {
              _inputMode = InputMode.totalMeses;
              _resultado = null;
            }),
          ),
        ],
      );

  Widget _buildInputFields() {
    if (_inputMode == InputMode.amd) {
      return Row(children: [
        Expanded(child: _fieldInteiro('Anos', _anosCtrl)),
        const SizedBox(width: 8),
        Expanded(child: _fieldInteiro('Meses', _mesesCtrl)),
        const SizedBox(width: 8),
        Expanded(child: _fieldInteiro('Dias', _diasCtrl)),
      ]);
    }
    if (_inputMode == InputMode.totalDias) {
      return Column(children: [
        _field('Total em dias', _totalDiasCtrl),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _decimais.toString(),
              items: ['0', '2', '4']
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _decimais = int.parse(v!)),
              decoration:
                  const InputDecoration(labelText: 'Casas decimais'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _arredondamento == 'none'
                  ? 'Nenhum'
                  : _arredondamento == 'up'
                      ? 'Para cima'
                      : 'Para baixo',
              items: ['Nenhum', 'Para cima', 'Para baixo']
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _arredondamento =
                  v == 'Para cima'
                      ? 'up'
                      : v == 'Para baixo'
                          ? 'down'
                          : 'none'),
              decoration:
                  const InputDecoration(labelText: 'Arredondamento'),
            ),
          ),
        ]),
      ]);
    }
    return _field('Total em meses', _totalMesesCtrl);
  }

  /// Aceita dígitos e ponto decimal (o parser usa `double.tryParse`, que
  /// exige `.` — não vírgula). Usado em "Total em dias" e "Total em meses".
  Widget _field(String label, TextEditingController ctrl) =>
      TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() => _erro = null),
      );

  /// Igual a `_field`, mas restrito a números inteiros — usado nos campos
  /// Anos/Meses/Dias, que não fazem sentido em valor fracionário.
  Widget _fieldInteiro(String label, TextEditingController ctrl) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() => _erro = null),
      );

  Widget _buildErro(String msg) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.dangerBg(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.error_outline_rounded,
              size: 16, color: AppTheme.dangerColor(context)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.dangerColor(context)))),
        ]),
      );

  Widget _buildResultados() {
    final r = _resultado!;
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
                child: Text('Resultados',
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
          Row(children: [
            Expanded(
                child: ResultCard(
                    label: 'Anos', value: '${r.anos}')),
            const SizedBox(width: 8),
            Expanded(
                child: ResultCard(
                    label: 'Meses', value: '${r.meses}')),
            const SizedBox(width: 8),
            Expanded(
                child:
                    ResultCard(label: 'Dias', value: '${r.dias}')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: ResultCard(
                    label: 'Total dias',
                    value: _fmt(r.totalDias))),
            const SizedBox(width: 8),
            Expanded(
                child: ResultCard(
                    label: 'Total meses',
                    value: _fmt(r.totalMeses, dec: _decimais))),
            const SizedBox(width: 8),
            Expanded(
                child: ResultCard(
                    label: 'Total anos',
                    value: _fmt(r.totalAnos, dec: _decimais))),
          ]),
          const SizedBox(height: 12),
          FormulaBox(text: _formula),
          const SizedBox(height: 10),
          const AvisoLegal(),
        ],
      ),
    );
  }
}
