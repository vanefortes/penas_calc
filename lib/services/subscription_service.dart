// lib/services/subscription_service.dart
//
// Camada de assinatura via RevenueCat. Centraliza:
// - inicialização do SDK
// - verificação de status de acesso (entitlement "premium")
// - compra e restauração de assinatura
//
// IMPORTANTE: troque _revenueCatApiKeyIOS pela API Key pública do seu
// projeto no RevenueCat (Project Settings → API Keys → Apple App Store).
// Essa chave é pública por design (fica embutida no app), não é segredo.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

/// ID do entitlement configurado no painel do RevenueCat.
/// Precisa ser IDÊNTICO ao "Entitlement name" cadastrado lá (inclusive
/// maiúsculas/minúsculas e espaços) — são strings comparadas literalmente.
/// Esse entitlement é compartilhado entre iOS e Android: quem assina em
/// uma plataforma e troca de aparelho continua reconhecido como assinante,
/// desde que esteja logado com o mesmo app_user_id (ver função `identify`).
const String kEntitlementPremium = 'Calculadora Penal Pro';

/// API Key pública do RevenueCat para iOS.
const String _revenueCatApiKeyIOS = 'test_BdVCehQRORqmwWFyFtOnmSVThwG';

/// API Key pública do RevenueCat para Android.
/// Troque pela chave gerada quando você configurar o app Google Play
/// dentro do mesmo projeto do RevenueCat (Apps → New app → Google Play).
const String _revenueCatApiKeyAndroid = 'goog_SUBSTITUA_PELA_SUA_CHAVE_ANDROID';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  bool _configured = false;

  /// Inicializa o SDK. Chame uma vez, no início do app (main.dart).
  Future<void> init() async {
    if (_configured) return;

    // Web (e qualquer plataforma que não seja iOS/Android) não tem loja de
    // apps nem implementação nativa do plugin — precisa sair ANTES de
    // chamar qualquer método do Purchases, senão ele lança
    // MissingPluginException e quebra a inicialização do app inteiro.
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return;
    }

    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.error,
    );

    final String apiKey;
    if (Platform.isIOS) {
      apiKey = _revenueCatApiKeyIOS;
    } else {
      apiKey = _revenueCatApiKeyAndroid;
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
  }

  /// Vincula o RevenueCat a um identificador de usuário estável (opcional).
  /// Útil se você quiser amarrar a assinatura ao e-mail/ID do perfil local,
  /// para o caso do usuário trocar de aparelho.
  Future<void> identify(String appUserId) async {
    if (appUserId.isEmpty) return;
    try {
      await Purchases.logIn(appUserId);
    } catch (_) {
      // Se falhar, mantém o ID anônimo gerado pelo RevenueCat — não é crítico.
    }
  }

  /// Retorna true se o usuário tem o entitlement "premium" ativo.
  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(kEntitlementPremium);
    } catch (_) {
      return false;
    }
  }

  /// Busca a offering padrão configurada no RevenueCat (com o pacote mensal).
  Future<Offering?> getCurrentOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (_) {
      return null;
    }
  }

  /// Realiza a compra de um pacote (ex: o plano mensal).
  /// Retorna true se a compra resultou em entitlement ativo.
  Future<PurchaseResult> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      final ativo = result.entitlements.active
          .containsKey(kEntitlementPremium);
      return PurchaseResult(sucesso: ativo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult(sucesso: false, cancelado: true);
      }
      return PurchaseResult(sucesso: false, erro: e.message);
    } catch (e) {
      return PurchaseResult(sucesso: false, erro: e.toString());
    }
  }

  /// Restaura compras anteriores (obrigatório pela Apple ter esse botão
  /// visível no paywall).
  Future<bool> restaurar() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(kEntitlementPremium);
    } catch (_) {
      return false;
    }
  }
}

class PurchaseResult {
  final bool sucesso;
  final bool cancelado;
  final String? erro;
  PurchaseResult({required this.sucesso, this.cancelado = false, this.erro});
}
