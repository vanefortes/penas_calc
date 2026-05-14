import 'package:flutter_test/flutter_test.dart';
import 'package:penas_calc/models/calculo.dart';

void main() {
  group('Modo padrão', () {
    const modo = ModoCalculo.padrao;

    test('1 ano = 365 dias', () {
      final r = CalculoEngine.converter(
          totalDiasInput: 365, modo: modo);
      expect(r.anos, 1);
      expect(r.meses, 0);
      expect(r.dias, 0);
    });

    test('1 mês = 30 dias', () {
      final r = CalculoEngine.converter(
          totalDiasInput: 30, modo: modo);
      expect(r.meses, 1);
      expect(r.dias, 0);
    });

    test('5 anos = 1825 dias', () {
      final td = CalculoEngine.calcTotalDias(
          anos: 5, meses: 0, dias: 0, modo: modo);
      expect(td, 1825.0);
    });

    test('decomposição de 400 dias', () {
      final r = CalculoEngine.converter(
          totalDiasInput: 400, modo: modo);
      expect(r.anos, 1);
      expect(r.meses, 1);
      expect(r.dias, 5);
    });
  });

  group('Projeção de data', () {
    test('data inicial + 5 anos', () {
      final inicio = DateTime(2020, 1, 1);
      final res = CalculoEngine.projetarData(
        dataInicio: inicio,
        anos: 5,
        meses: 0,
        dias: 0,
        modo: ModoCalculo.padrao,
      );
      final esperado =
          inicio.add(const Duration(days: 1825));
      expect(res.dataFim.year, esperado.year);
      expect(res.dataFim.month, esperado.month);
      expect(res.dataFim.day, esperado.day);
    });

    test('fração 1/3 de 3 anos = 365 dias', () {
      final res = CalculoEngine.projetarData(
        dataInicio: DateTime(2020, 1, 1),
        anos: 3,
        meses: 0,
        dias: 0,
        modo: ModoCalculo.padrao,
        fracao: 1 / 3,
      );
      expect(res.diasFracao, 365);
    });
  });

  group('Entre datas', () {
    test('1 ano exato (2020 bissexto)', () {
      final res = CalculoEngine.calcularEntreDatas(
        dataInicio: DateTime(2020, 1, 1),
        dataFim: DateTime(2021, 1, 1),
      );
      expect(res.anos, 1);
      expect(res.totalDias, 366);
    });

    test('fevereiro bissexto = 29 dias', () {
      final res = CalculoEngine.calcularEntreDatas(
        dataInicio: DateTime(2020, 2, 1),
        dataFim: DateTime(2020, 3, 1),
      );
      expect(res.totalDias, 29);
    });
  });
}
