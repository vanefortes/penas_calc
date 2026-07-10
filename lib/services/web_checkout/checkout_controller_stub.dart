// lib/services/web_checkout/checkout_controller_stub.dart
//
// Versão "vazia" usada em iOS/Android — nunca deveria ser chamada de fato
// (as telas checam kIsWeb antes), mas precisa existir pra compilar em
// todas as plataformas.

class WebPackage {
  final String identifier;
  final String precoFormatado;
  const WebPackage({required this.identifier, required this.precoFormatado});
  String get rotulo => identifier;
}

class WebCheckoutController {
  Future<void> configurar({
    required String apiKey,
    required String appUserId,
  }) async {}

  Future<List<WebPackage>> buscarOfertas() async => [];

  Future<Map<String, dynamic>> comprar(WebPackage pacote) async => {
        'sucesso': false,
        'cancelado': false,
        'erro': 'Checkout web indisponível nesta plataforma.',
      };
}
