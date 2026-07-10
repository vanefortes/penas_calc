import 'package:flutter/services.dart';

/// Máscara para o campo OAB no padrão 123.456/PR
/// - aceita no máximo 6 dígitos, com ponto separando os 3 primeiros dos 3 últimos
/// - insere o ponto "." e a barra "/" automaticamente
/// - aceita no máximo 2 letras depois da barra, sempre convertidas para maiúsculas
class OabInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();

    final digitsAll = upper.replaceAll(RegExp(r'[^0-9]'), '');
    final digits = digitsAll.length > 6 ? digitsAll.substring(0, 6) : digitsAll;

    final digitsFormatted = digits.length > 3
        ? '${digits.substring(0, 3)}.${digits.substring(3)}'
        : digits;

    final lettersAll = upper.replaceAll(RegExp(r'[^A-Z]'), '');
    final uf = lettersAll.length > 2 ? lettersAll.substring(0, 2) : lettersAll;

    final formatted = uf.isNotEmpty ? '$digitsFormatted/$uf' : digitsFormatted;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
