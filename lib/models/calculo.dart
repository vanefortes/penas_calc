import 'package:intl/intl.dart';

enum ModoCalculo { padrao, calendarioReal, juridico }

extension ModoCalculoExt on ModoCalculo {
  String get nome {
    switch (this) {
      case ModoCalculo.padrao:        return 'Padrão';
      case ModoCalculo.calendarioReal: return 'Calendário Real';
      case ModoCalculo.juridico:      return 'Jurídico';
    }
  }

  String get descricao {
    switch (this) {
      case ModoCalculo.padrao:        return '1 ano = 365 dias · 1 mês = 30 dias';
      case ModoCalculo.calendarioReal: return 'Dias reais de cada mês + anos bissextos';
      case ModoCalculo.juridico:      return '1 ano = 365 dias · 1 mês = 365/12 dias';
    }
  }

  double get diasPorMes {
    switch (this) {
      case ModoCalculo.padrao:        return 30.0;
      case ModoCalculo.calendarioReal: return 365.2425 / 12.0;
      case ModoCalculo.juridico:      return 365.0 / 12.0;
    }
  }

  double get diasPorAno {
    switch (this) {
      case ModoCalculo.padrao:        return 365.0;
      case ModoCalculo.calendarioReal: return 365.2425;
      case ModoCalculo.juridico:      return 365.0;
    }
  }
}

class Calendario {
  static bool isBissexto(int ano) =>
      (ano % 4 == 0 && ano % 100 != 0) || (ano % 400 == 0);

  static int diasNoMes(int ano, int mes) {
    const d = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (mes == 2 && isBissexto(ano)) return 29;
    return d[mes];
  }

  static DateTime somarPeriodo(
      DateTime base, int anos, int meses, int dias) {
    int ano = base.year + anos;
    int mes = base.month + meses;
    int dia = base.day;
    while (mes > 12) { mes -= 12; ano++; }
    while (mes < 1)  { mes += 12; ano--; }
    final maxDia = diasNoMes(ano, mes);
    if (dia > maxDia) dia = maxDia;
    return DateTime(ano, mes, dia).add(Duration(days: dias));
  }

  static int diasEntre(DateTime inicio, DateTime fim) =>
      fim.difference(inicio).inDays;

  static ({int anos, int meses, int dias}) decompor(
      DateTime base, int totalDias) {
    DateTime cursor = base;
    int anos = 0, meses = 0;

    while (totalDias > 0) {
      final proxAno = DateTime(cursor.year + 1, cursor.month, cursor.day);
      final diff = proxAno.difference(cursor).inDays;
      if (totalDias >= diff) { totalDias -= diff; anos++; cursor = proxAno; }
      else break;
    }

    while (totalDias > 0) {
      int proxMes = cursor.month + 1;
      int proxAno = cursor.year;
      if (proxMes > 12) { proxMes = 1; proxAno++; }
      final maxDia = diasNoMes(proxAno, proxMes);
      final diaAj = cursor.day > maxDia ? maxDia : cursor.day;
      final proxData = DateTime(proxAno, proxMes, diaAj);
      final diff = proxData.difference(cursor).inDays;
      if (totalDias >= diff) { totalDias -= diff; meses++; cursor = proxData; }
      else break;
    }

    return (anos: anos, meses: meses, dias: totalDias);
  }

  static int contarBissextos(DateTime inicio, DateTime fim) {
    int count = 0;
    for (int ano = inicio.year; ano <= fim.year; ano++) {
      if (isBissexto(ano)) {
        final d = DateTime(ano, 2, 29);
        if (!d.isBefore(inicio) && !d.isAfter(fim)) count++;
      }
    }
    return count;
  }
}

class PeriodoDecomposto {
  final int anos, meses, dias;
  final double totalDias, totalMeses, totalAnos;
  final String? observacao;

  PeriodoDecomposto({
    required this.anos, required this.meses, required this.dias,
    required this.totalDias, required this.totalMeses, required this.totalAnos,
    this.observacao,
  });
}

class ResultadoProjecao {
  final DateTime dataFim;
  final PeriodoDecomposto periodo;
  final DateTime? dataFracao;
  final int? diasFracao;
  final String? nomeFracao;
  final String detalhes;

  ResultadoProjecao({
    required this.dataFim, required this.periodo, required this.detalhes,
    this.dataFracao, this.diasFracao, this.nomeFracao,
  });
}

class ResultadoEntreDatas {
  final int anos, meses, dias, totalDias;
  final String detalhes;

  ResultadoEntreDatas({
    required this.anos, required this.meses, required this.dias,
    required this.totalDias, required this.detalhes,
  });
}

class CalculoEngine {
  static String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  static PeriodoDecomposto converter({
    required double totalDiasInput,
    required ModoCalculo modo,
    DateTime? dataBase,
  }) {
    final dpm = modo.diasPorMes;
    final dpa = modo.diasPorAno;
    final totalDias = totalDiasInput;
    int anosInt, mesesInt, diasInt;
    String? obs;

    if (modo == ModoCalculo.calendarioReal) {
      final base = dataBase ?? DateTime(2000, 1, 1);
      final decomp = Calendario.decompor(base, totalDias.round());
      anosInt = decomp.anos; mesesInt = decomp.meses; diasInt = decomp.dias;
      obs = 'Base: ${_fmtDate(base)} · dias reais + bissextos';
    } else {
      anosInt = (totalDias / dpa).floor();
      final restDias = totalDias - anosInt * dpa;
      mesesInt = (restDias / dpm).floor();
      diasInt = (restDias - mesesInt * dpm).round();
    }

    return PeriodoDecomposto(
      anos: anosInt, meses: mesesInt, dias: diasInt,
      totalDias: totalDias, totalMeses: totalDias / dpm,
      totalAnos: totalDias / dpa, observacao: obs,
    );
  }

  static double calcTotalDias({
    required int anos, required int meses, required int dias,
    required ModoCalculo modo, DateTime? dataBase,
  }) {
    if (modo == ModoCalculo.calendarioReal && dataBase != null) {
      final df = Calendario.somarPeriodo(dataBase, anos, meses, dias);
      return Calendario.diasEntre(dataBase, df).toDouble();
    }
    return anos * modo.diasPorAno + meses * modo.diasPorMes + dias.toDouble();
  }

  static ResultadoProjecao projetarData({
    required DateTime dataInicio,
    required int anos, required int meses, required int dias,
    required ModoCalculo modo,
    double? fracao, String? nomeFracao,
  }) {
    late DateTime dataFim;
    late double totalDias;
    late String detalhes;

    if (modo == ModoCalculo.calendarioReal) {
      dataFim = Calendario.somarPeriodo(dataInicio, anos, meses, dias);
      totalDias = Calendario.diasEntre(dataInicio, dataFim).toDouble();
      final biss = Calendario.contarBissextos(dataInicio, dataFim);
      detalhes = 'Modo Calendário Real · dias reais de cada mês\n'
          'Anos bissextos no período: $biss\n'
          'Total exato: ${totalDias.toInt()} dias corridos';
    } else {
      totalDias = calcTotalDias(anos: anos, meses: meses, dias: dias, modo: modo);
      dataFim = dataInicio.add(Duration(days: totalDias.round()));
      final dpmStr = modo.diasPorMes == modo.diasPorMes.roundToDouble()
          ? modo.diasPorMes.toInt().toString()
          : modo.diasPorMes.toStringAsFixed(4);
      detalhes = 'Modo ${modo.nome}: 1 ano = ${modo.diasPorAno.toInt()} dias '
          '· 1 mês = $dpmStr dias\nTotal: ${totalDias.toInt()} dias';
    }

    final periodo = converter(
        totalDiasInput: totalDias, modo: modo, dataBase: dataInicio);

    DateTime? dataFrac;
    int? diasFrac;
    if (fracao != null && fracao < 1.0) {
      diasFrac = (totalDias * fracao).round();
      dataFrac = dataInicio.add(Duration(days: diasFrac));
    }

    return ResultadoProjecao(
      dataFim: dataFim, periodo: periodo, detalhes: detalhes,
      dataFracao: dataFrac, diasFracao: diasFrac, nomeFracao: nomeFracao,
    );
  }

  static ResultadoEntreDatas calcularEntreDatas({
    required DateTime dataInicio, required DateTime dataFim,
  }) {
    final totalDias = Calendario.diasEntre(dataInicio, dataFim);
    final decomp = Calendario.decompor(dataInicio, totalDias);
    final biss = Calendario.contarBissextos(dataInicio, dataFim);
    return ResultadoEntreDatas(
      anos: decomp.anos, meses: decomp.meses, dias: decomp.dias,
      totalDias: totalDias,
      detalhes: 'Cálculo pelo calendário civil real\n'
          'Anos bissextos no período: $biss\n'
          'Total: $totalDias dias corridos',
    );
  }
}

class HistoricoItem {
  final String id;
  final DateTime timestamp;
  final String tipo, entrada, saida, modo;
  final bool progressao;

  HistoricoItem({
    required this.id, required this.timestamp, required this.tipo,
    required this.entrada, required this.saida, required this.modo,
    this.progressao = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'timestamp': timestamp.toIso8601String(),
    'tipo': tipo, 'entrada': entrada, 'saida': saida,
    'modo': modo, 'progressao': progressao,
  };

  factory HistoricoItem.fromJson(Map<String, dynamic> json) => HistoricoItem(
    id: json['id'], timestamp: DateTime.parse(json['timestamp']),
    tipo: json['tipo'], entrada: json['entrada'],
    saida: json['saida'], modo: json['modo'],
    progressao: json['progressao'] ?? false,
  );

  String get timestampFormatado =>
      DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
}