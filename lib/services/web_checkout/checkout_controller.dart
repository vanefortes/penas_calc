// lib/services/web_checkout/checkout_controller.dart
//
// Ponto único de import. Em builds Web, usa a implementação de verdade
// (JS interop com a RevenueCat); em iOS/Android, usa uma versão vazia,
// só pra compilar — essas plataformas usam purchases_flutter normalmente.

export 'checkout_controller_stub.dart'
    if (dart.library.js_interop) 'checkout_controller_web.dart';
