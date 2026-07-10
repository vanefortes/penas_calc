// lib/services/web_checkout/checkout_controller_web.dart
//
// Ponte entre o Dart e o SDK JS da RevenueCat (@revenuecat/purchases-js,
// carregado via <script> em web/index.html) para o checkout de assinatura
// na Web. Usa a camada HTML criada em web/index.html
// (#rc-checkout-overlay / #rc-checkout-target), fora da árvore de widgets
// do Flutter, controlada via dart:html + dart:js_util.
//
// A seleção de plano é feita com widgets Flutter (paywall_screen.dart),
// não com o paywall visual da RevenueCat — só a etapa de pagamento em si
// (coleta do cartão) é hospedada por eles, por questão de segurança/PCI.

import 'dart:js_util' as js_util;

import '../subscription_service.dart' show kEntitlementPremium;

/// Representa um pacote/plano disponível no checkout web, já com o preço
/// formatado. Guarda a referência crua do objeto JS (necessária pra
/// chamar purchase() depois).
class WebPackage {
  final String identifier;
  final String precoFormatado;
  final Object jsPackage;

  WebPackage({
    required this.identifier,
    required this.precoFormatado,
    required this.jsPackage,
  });

  /// Rótulo em português, baseado no identifier padrão da RevenueCat
  /// ($rc_weekly, $rc_monthly, $rc_annual).
  String get rotulo {
    switch (identifier) {
      case r'$rc_weekly':
        return 'Semanal';
      case r'$rc_monthly':
        return 'Mensal';
      case r'$rc_annual':
        return 'Anual';
      default:
        return identifier;
    }
  }
}

class WebCheckoutController {
  bool _configurado = false;

  Object? get _purchasesNamespace =>
      js_util.getProperty(js_util.globalThis, 'Purchases');

  Object _purchasesClass() {
    final ns = _purchasesNamespace;
    if (ns == null) {
      throw Exception(
        'SDK da RevenueCat não carregado. Confira o <script src="https://unpkg.com/@revenuecat/purchases-js@1/dist/Purchases.umd.js"> em web/index.html.',
      );
    }
    return js_util.getProperty(ns, 'Purchases');
  }

  Object _sharedInstance() {
    final purchasesClass = _purchasesClass();
    return js_util.callMethod(purchasesClass, 'getSharedInstance', []);
  }

  /// Configura o SDK JS uma única vez. Chame assim que souber o
  /// appUserId (ex: e-mail do usuário logado).
  Future<void> configurar({
    required String apiKey,
    required String appUserId,
  }) async {
    if (_configurado) return;

    final purchasesClass = _purchasesClass();
    final params = js_util.newObject();
    js_util.setProperty(params, 'apiKey', apiKey);
    js_util.setProperty(params, 'appUserId', appUserId);
    js_util.callMethod(purchasesClass, 'configure', [params]);
    _configurado = true;
  }

  /// Busca a offering atual e devolve os pacotes disponíveis, prontos pra
  /// montar sua própria tela de seleção de plano (em vez do template
  /// visual da RevenueCat).
  Future<List<WebPackage>> buscarOfertas() async {
    if (!_configurado) return [];

    final sharedInstance = _sharedInstance();
    final promise = js_util.callMethod(sharedInstance, 'getOfferings', []);
    final offerings = await js_util.promiseToFuture(promise);

    final current = js_util.getProperty(offerings, 'current');
    if (current == null) return [];

    final availablePackages =
        js_util.getProperty(current, 'availablePackages');
    final length = js_util.getProperty(availablePackages, 'length') as int;

    final pacotes = <WebPackage>[];
    for (var i = 0; i < length; i++) {
      final pkg = js_util.getProperty(availablePackages, i);
      final identifier = js_util.getProperty(pkg, 'identifier') as String;
      final product = js_util.getProperty(pkg, 'webBillingProduct');
      final price = js_util.getProperty(product, 'currentPrice');
      final precoFormatado =
          js_util.getProperty(price, 'formattedPrice') as String;

      pacotes.add(WebPackage(
        identifier: identifier,
        precoFormatado: precoFormatado,
        jsPackage: pkg,
      ));
    }

    return pacotes;
  }

  /// Compra o pacote selecionado. Mostra o formulário de pagamento
  /// (hospedado pela RevenueCat/Stripe) dentro da camada criada em
  /// web/index.html — a seleção de plano em si já aconteceu na sua UI.
  ///
  /// Retorna um mapa com:
  /// - sucesso: true se o pagamento foi concluído e o entitlement
  ///   "premium" ficou ativo
  /// - cancelado: true se o usuário fechou o checkout sem pagar
  /// - erro: mensagem de erro, se algo deu errado
  Future<Map<String, dynamic>> comprar(WebPackage pacote) async {
    if (!_configurado) {
      return {
        'sucesso': false,
        'cancelado': false,
        'erro': 'Checkout não configurado. Chame configurar() antes.',
      };
    }

    final sharedInstance = _sharedInstance();

    try {
      final params = js_util.newObject();
      js_util.setProperty(params, 'rcPackage', pacote.jsPackage);
      // Propositalmente NÃO passamos htmlTarget aqui: ao contrário do
      // presentPaywall(), o purchase() cria seu próprio modal flutuante
      // (via um "top layer" próprio) em outro ponto do body. Tentar
      // forçar ele pra dentro da nossa camada (#rc-checkout-overlay)
      // deixava esse modal preso em display:none — melhor deixar a
      // RevenueCat controlar o próprio overlay dela sem interferência.

      final promise = js_util.callMethod(sharedInstance, 'purchase', [params]);
      if (promise == null) {
        throw Exception('purchase() não retornou uma Promise válida.');
      }

      final result = await js_util.promiseToFuture(promise);

      final customerInfo = js_util.getProperty(result, 'customerInfo');
      final entitlements = js_util.getProperty(customerInfo, 'entitlements');
      final active = js_util.getProperty(entitlements, 'active');
      final premiumAtivo =
          js_util.hasProperty(active, kEntitlementPremium);

      return {'sucesso': premiumAtivo, 'cancelado': false};
    } catch (e) {
      final msg = e.toString();
      final cancelado = msg.toLowerCase().contains('cancel');

      return {
        'sucesso': false,
        'cancelado': cancelado,
        if (!cancelado) 'erro': msg,
      };
    }
  }
}
