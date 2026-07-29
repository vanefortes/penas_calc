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
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';

/// ID do entitlement configurado no painel do RevenueCat.
/// Precisa ser IDÊNTICO ao "Entitlement name" cadastrado lá (inclusive
/// maiúsculas/minúsculas e espaços) — são strings comparadas literalmente.
/// Esse entitlement é compartilhado entre iOS, Android e Web: quem assina em
/// uma plataforma e troca de aparelho continua reconhecido como assinante,
/// desde que esteja logado com o mesmo app_user_id (ver função `identify`).
const String kEntitlementPremium = 'Calculadora Penal Pro';

/// Endpoint (Vercel) que verifica a assinatura via API REST da RevenueCat,
/// usado apenas na Web (mobile consulta direto pelo SDK nativo).
const String kCheckSubscriptionUrl =
    'https://penas-calc.vercel.app/api/check-subscription';

/// Chave PÚBLICA (sandbox) do checkout Web (RevenueCat Billing).
/// Pegue em: RevenueCat → API keys → SDK API keys → linha
/// "Calculadora Penal (RevenueCat Billing)" → Show key.
/// Troque pela chave de PRODUÇÃO quando for lançar de verdade — a sandbox
/// só processa pagamentos de teste do Stripe.
const String kWebBillingApiKey = 'rcb_sb_jamCGpCEjTQGXOvZitgTIFtiY';

/// API Key pública do RevenueCat para iOS.
const String _revenueCatApiKeyIOS = 'appl_MrEXJipELQsyFqXAJVOozHxkeiI';

/// API Key pública do RevenueCat para Android.
/// Troque pela chave gerada quando você configurar o app Google Play
/// dentro do mesmo projeto do RevenueCat (Apps → New app → Google Play).
const String _revenueCatApiKeyAndroid = 'goog_nMhDOECpdlhXPIKzEAJYungpcvm';

class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  bool _configured = false;

  /// ID estável do usuário (hoje, o e-mail). Guardado aqui porque na Web
  /// não existe SDK nativo — usamos esse valor pra consultar o endpoint
  /// de assinatura na Vercel.
  String? _currentAppUserId;

  /// Exposto para a tela de checkout web usar o mesmo appUserId.
  String? get currentAppUserId => _currentAppUserId;

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

  /// Vincula o RevenueCat a um identificador de usuário estável — hoje,
  /// o e-mail cadastrado no app. Chame sempre que o e-mail do usuário for
  /// conhecido/carregado (login, primeiro acesso, restauração de sessão).
  /// Isso é o que permite reconhecer a mesma assinatura em iOS, Android e Web.
  Future<void> identify(String appUserId) async {
    if (appUserId.isEmpty) return;
    _currentAppUserId = appUserId;

    // Na Web não existe SDK nativo — o vínculo é feito só guardando o ID
    // acima, usado depois pelo isPremium() e pelo checkout web.
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;

    try {
      await Purchases.logIn(appUserId);
    } catch (_) {
      // Se falhar, mantém o ID anônimo gerado pelo RevenueCat — não é crítico.
    }
  }

  /// Retorna true se o usuário tem o entitlement "premium" ativo.
  Future<bool> isPremium() async {
    if (kIsWeb) return _isPremiumWeb();

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(kEntitlementPremium);
    } catch (_) {
      return false;
    }
  }

  /// Checagem de assinatura na Web, via endpoint próprio (Vercel), já que
  /// o SDK do RevenueCat não roda nativamente nessa plataforma.
  Future<bool> _isPremiumWeb() async {
    final appUserId = _currentAppUserId;
    if (appUserId == null || appUserId.isEmpty) return false;

    try {
      final uri = Uri.parse(kCheckSubscriptionUrl)
          .replace(queryParameters: {'appUserId': appUserId});
      final response = await http.get(uri);
      if (response.statusCode != 200) return false;
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['premium'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Busca o link do Customer Portal da RevenueCat (onde o usuário troca
  /// cartão, vê fatura, cancela, etc.) pra assinaturas feitas na Web.
  /// Retorna null se não houver assinatura ou o link não estiver disponível.
  Future<String?> getManagementUrlWeb() async {
    final appUserId = _currentAppUserId;
    if (appUserId == null || appUserId.isEmpty) return null;

    try {
      final uri = Uri.parse(kCheckSubscriptionUrl)
          .replace(queryParameters: {'appUserId': appUserId});
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['managementUrl'] as String?;
    } catch (_) {
      return null;
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
      // A partir do purchases_flutter v9, purchasePackage() retorna o tipo
      // `PurchaseResult` do próprio SDK (com `customerInfo` e
      // `storeTransaction`), e não mais um `CustomerInfo` direto como na v8.
      final sdkResult = await Purchases.purchasePackage(package);
      final ativo = sdkResult.customerInfo.entitlements.active
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
