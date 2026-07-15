// lib/services/update_service.dart
//
// Verifica se há uma versão mais nova do app disponível nas lojas.
//
// — Android: usa a API NATIVA do Google (Play Core / pacote
//   `in_app_update` — ver `AndroidUpdateService`, em
//   `lib/services/android_update_service.dart`). Ela consulta a Play
//   Store diretamente pra faixa (interna/fechada/produção) em que aquele
//   usuário está, então não depende de nenhum backend nosso nem sofre
//   com o atraso da revisão da loja.
//
// — iOS: consulta direto a API pública da Apple (iTunes Lookup). A
//   versão e as notas mostradas são sempre as mesmas que você já
//   preenche no App Store Connect ao publicar — nada para manter aqui.
//   (A Apple não tem um equivalente ao Play Core, então seguimos com
//   uma tela própria + link para a App Store.)

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Bundle ID do app na App Store — usado na consulta pública da Apple.
const String kAppStoreBundleId = 'com.vforttes.penascalc';

/// Link de fallback, caso a resposta da Apple não venha com uma URL própria.
const String kUrlPlayStoreFallback =
    'https://play.google.com/store/apps/details?id=com.vforttes.penas_calc';

class UpdateInfo {
  /// Se existe uma versão mais nova que a instalada.
  final bool disponivel;

  /// Se a atualização é obrigatória. A Apple não expõe uma "versão
  /// mínima" publicamente, então este campo é sempre `false` aqui — só
  /// é usado de fato no fluxo nativo do Android (ver AndroidUpdateInfo).
  final bool obrigatoria;

  final String versaoAtual;
  final String versaoNova;
  final String notas;
  final String urlLoja;

  const UpdateInfo({
    required this.disponivel,
    required this.obrigatoria,
    required this.versaoAtual,
    required this.versaoNova,
    required this.notas,
    required this.urlLoja,
  });

  static const vazio = UpdateInfo(
    disponivel: false,
    obrigatoria: false,
    versaoAtual: '',
    versaoNova: '',
    notas: '',
    urlLoja: '',
  );
}

class UpdateService {
  UpdateService._();

  /// Verificação para iOS (e no-op na Web). No Android, use
  /// `AndroidUpdateService` em vez desta classe.
  static Future<UpdateInfo> verificarIOS() async {
    if (kIsWeb) return UpdateInfo.vazio;

    try {
      final pacote = await PackageInfo.fromPlatform();
      final versaoAtual = pacote.version;

      final resposta = await http
          .get(Uri.parse(
              'https://itunes.apple.com/lookup?bundleId=$kAppStoreBundleId'))
          .timeout(const Duration(seconds: 4));

      if (resposta.statusCode != 200) return UpdateInfo.vazio;

      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      final resultados = dados['results'] as List?;
      if (resultados == null || resultados.isEmpty) return UpdateInfo.vazio;

      final app = resultados.first as Map<String, dynamic>;
      final versaoNova = (app['version'] as String?)?.trim() ?? '';
      if (versaoNova.isEmpty) return UpdateInfo.vazio;
      if (!versaoMenor(versaoAtual, versaoNova)) return UpdateInfo.vazio;

      final notas = (app['releaseNotes'] as String?)?.trim() ?? '';
      final urlLoja = (app['trackViewUrl'] as String?)?.trim() ?? '';
      final trackId = app['trackId'];

      return UpdateInfo(
        disponivel: true,
        obrigatoria: false,
        versaoAtual: versaoAtual,
        versaoNova: versaoNova,
        notas: notas,
        urlLoja: urlLoja.isNotEmpty
            ? urlLoja
            : (trackId != null
                ? 'https://apps.apple.com/app/id$trackId'
                : kUrlPlayStoreFallback),
      );
    } catch (_) {
      return UpdateInfo.vazio;
    }
  }

  /// Compara duas versões no formato "x.y.z" (aceita tamanhos diferentes,
  /// ex: "1.2" vs "1.2.1"). Retorna true se [atual] for menor que [outra].
  static bool versaoMenor(String atual, String outra) {
    final a = atual.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final b = outra.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final tamanho = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < tamanho; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }
}
