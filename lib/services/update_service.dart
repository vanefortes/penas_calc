// lib/services/update_service.dart
//
// Verifica se há uma versão mais nova do app disponível nas lojas.
//
// — iOS: consulta direto a API pública da Apple (iTunes Lookup). A
//   versão e as notas mostradas são sempre as mesmas que você já
//   preenche no App Store Connect ao publicar — nada para manter aqui.
//
// — Android: consulta um endpoint próprio (Vercel) que lê a versão
//   automaticamente do pubspec.yaml no GitHub (ver api/check-version.js)
//   — então o único passo de release no Android é dar bump na versão
//   e fazer push. As notas de versão e uma eventual atualização
//   obrigatória ainda são configuradas manualmente nesse endpoint.

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Endpoint (Vercel) usado apenas para Android.
const String kCheckVersionUrl =
    'https://penas-calc.vercel.app/api/check-version';

/// Bundle ID do app na App Store — usado na consulta pública da Apple.
const String kAppStoreBundleId = 'com.vforttes.penascalc';

/// Link de fallback, caso a resposta da Apple não venha com uma URL própria.
const String _urlPlayStoreFallback =
    'https://play.google.com/store/apps/details?id=com.vforttes.penas_calc';

class UpdateInfo {
  /// Se existe uma versão mais nova que a instalada.
  final bool disponivel;

  /// Se a atualização é obrigatória (versão instalada abaixo da mínima
  /// aceita) — nesse caso o app não deve permitir seguir sem atualizar.
  /// Só se aplica ao Android; a Apple não expõe uma "versão mínima".
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

  /// Nunca lança exceção: qualquer falha (rede, timeout, resposta
  /// inesperada) resulta em [UpdateInfo.vazio], para nunca bloquear o
  /// acesso ao app por causa dessa verificação.
  static Future<UpdateInfo> verificar() async {
    // Na Web o app é sempre a versão mais recente publicada.
    if (kIsWeb) return UpdateInfo.vazio;

    try {
      final pacote = await PackageInfo.fromPlatform();
      final versaoAtual = pacote.version;

      return Platform.isIOS
          ? await _verificarIOS(versaoAtual)
          : await _verificarAndroid(versaoAtual);
    } catch (_) {
      return UpdateInfo.vazio;
    }
  }

  /// iOS: consulta direto a API pública da Apple, sem depender de
  /// nenhum backend próprio.
  static Future<UpdateInfo> _verificarIOS(String versaoAtual) async {
    try {
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
      if (!_versaoMenor(versaoAtual, versaoNova)) return UpdateInfo.vazio;

      final notas = (app['releaseNotes'] as String?)?.trim() ?? '';
      final urlLoja = (app['trackViewUrl'] as String?)?.trim() ?? '';
      final trackId = app['trackId'];

      return UpdateInfo(
        disponivel: true,
        // A Apple não expõe uma "versão mínima obrigatória" — nunca
        // forçamos atualização a partir dessa fonte.
        obrigatoria: false,
        versaoAtual: versaoAtual,
        versaoNova: versaoNova,
        notas: notas,
        urlLoja: urlLoja.isNotEmpty
            ? urlLoja
            : (trackId != null
                ? 'https://apps.apple.com/app/id$trackId'
                : _urlPlayStoreFallback),
      );
    } catch (_) {
      return UpdateInfo.vazio;
    }
  }

  /// Android: consulta o endpoint próprio, que lê a versão automaticamente
  /// do pubspec.yaml no GitHub (ver api/check-version.js).
  static Future<UpdateInfo> _verificarAndroid(String versaoAtual) async {
    try {
      final resposta = await http
          .get(Uri.parse('$kCheckVersionUrl?platform=android'))
          .timeout(const Duration(seconds: 4));

      if (resposta.statusCode != 200) return UpdateInfo.vazio;

      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      final versaoNova = (dados['latestVersion'] as String?)?.trim() ?? '';
      if (versaoNova.isEmpty) return UpdateInfo.vazio;

      final versaoMinima = (dados['minVersion'] as String?)?.trim() ?? '';
      final notas = (dados['notes'] as String?)?.trim() ?? '';
      final urlLojaResposta = (dados['url'] as String?)?.trim() ?? '';
      final urlLoja =
          urlLojaResposta.isNotEmpty ? urlLojaResposta : _urlPlayStoreFallback;

      if (!_versaoMenor(versaoAtual, versaoNova)) return UpdateInfo.vazio;

      final obrigatoria =
          versaoMinima.isNotEmpty && _versaoMenor(versaoAtual, versaoMinima);

      return UpdateInfo(
        disponivel: true,
        obrigatoria: obrigatoria,
        versaoAtual: versaoAtual,
        versaoNova: versaoNova,
        notas: notas,
        urlLoja: urlLoja,
      );
    } catch (_) {
      return UpdateInfo.vazio;
    }
  }

  /// Compara duas versões no formato "x.y.z" (aceita tamanhos diferentes,
  /// ex: "1.2" vs "1.2.1"). Retorna true se [atual] for menor que [outra].
  static bool _versaoMenor(String atual, String outra) {
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
