// lib/services/android_update_service.dart
//
// Verificação e disparo de atualização usando a API nativa do Google
// (Play Core, via pacote `in_app_update`). Diferente da checagem por
// HTTP que usamos no iOS, esta consulta a própria Play Store — pela
// faixa (interna/fechada/produção) em que o usuário instalou o app — e
// por isso não sofre com o atraso entre publicar o código e a loja
// aprovar a versão.
//
// Dois modos de atualização, decididos pelo Google:
//   — Imediata (immediate): tela cheia nativa, bloqueante — usada
//     quando a atualização tem prioridade alta (ver kPrioridadeMinimaObrigatoria).
//   — Flexível (flexible): baixa em segundo plano; o usuário decide
//     quando reiniciar para instalar. Usada para atualizações opcionais.
//
// IMPORTANTE: só funciona em apps instalados via Google Play (qualquer
// faixa — interna, fechada, aberta ou produção). Em builds de debug,
// sideload (APK direto) ou emulador sem Play Store, a checagem
// simplesmente falha e tratamos como "sem atualização disponível" — não
// bloqueia o desenvolvimento nem os testes locais.
//
// A "prioridade" de uma atualização é definida por VOCÊ ao publicar uma
// nova versão: Play Console → sua app → Release → (o campo de
// prioridade do in-app update fica disponível via Play Developer API;
// se você não usa a API para publicar, o valor padrão é 0 — ou seja,
// por padrão NENHUMA atualização é tratada como obrigatória).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_update/in_app_update.dart';

/// A partir de qual prioridade (0–5) uma atualização passa a ser tratada
/// como obrigatória (tela nativa do Google, sem opção de continuar sem
/// atualizar). Ajuste esse número conforme a política que você definir
/// ao publicar as versões.
const int kPrioridadeMinimaObrigatoria = 4;

enum AndroidUpdateResultado {
  /// Nenhuma atualização disponível (ou checagem indisponível — ex:
  /// app não instalado via Play Store).
  nenhuma,

  /// Atualização obrigatória: a tela nativa do Google já foi (ou está
  /// sendo) exibida — nada mais a fazer na nossa UI.
  imediataEmAndamento,

  /// Atualização opcional disponível — mostre a tela própria e, se o
  /// usuário aceitar, chame [AndroidUpdateService.iniciarFlexivel].
  flexivelDisponivel,
}

class AndroidUpdateService {
  AndroidUpdateService._();

  /// Consulta a Play Store e, se for uma atualização obrigatória, já
  /// aciona a tela nativa do Google (bloqueante) antes de retornar.
  /// Nunca lança exceção — qualquer falha vira [AndroidUpdateResultado.nenhuma].
  static Future<AndroidUpdateResultado> verificar() async {
    if (kIsWeb) return AndroidUpdateResultado.nenhuma;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return AndroidUpdateResultado.nenhuma;
      }

      final obrigatoria = info.updatePriority >= kPrioridadeMinimaObrigatoria &&
          info.immediateUpdateAllowed;

      if (obrigatoria) {
        // Deixa a UI nativa do Google assumir a tela — cheia e
        // bloqueante. Se o usuário concluir, o Android reinicia o app
        // sozinho; se cancelar (ou der erro), seguimos normalmente em
        // vez de travar o usuário sem alternativa nenhuma.
        try {
          await InAppUpdate.performImmediateUpdate();
        } catch (_) {
          // Ignora — o usuário pode ter cancelado, ou o dispositivo não
          // suporta o fluxo imediato nesse momento.
        }
        return AndroidUpdateResultado.imediataEmAndamento;
      }

      if (info.flexibleUpdateAllowed) {
        return AndroidUpdateResultado.flexivelDisponivel;
      }

      return AndroidUpdateResultado.nenhuma;
    } catch (_) {
      return AndroidUpdateResultado.nenhuma;
    }
  }

  /// Inicia o download em segundo plano de uma atualização flexível
  /// (opcional) e, ao concluir com sucesso, aciona a instalação (que
  /// reinicia o app). Retorna `true` se a instalação foi disparada.
  static Future<bool> iniciarFlexivel() async {
    try {
      final resultado = await InAppUpdate.startFlexibleUpdate();
      if (resultado != AppUpdateResult.success) return false;

      // Reinicia o app já com a nova versão instalada.
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (_) {
      return false;
    }
  }
}
