// lib/services/app_state.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculo.dart';
import '../theme/app_theme.dart';
import 'google_auth_service.dart';
import 'subscription_service.dart';

/// Quantos cálculos um usuário sem assinatura pode fazer gratuitamente,
/// antes do paywall passar a bloquear novos cálculos.
const int kLimiteCalculosGratis = 10;

class AppState extends ChangeNotifier {
  ModoCalculo _modoCalculo = ModoCalculo.padrao;
  ThemeMode   _themeMode   = ThemeMode.system;
  AppTemplate _template    = AppTemplate.navyDourado;

  // ── Assinatura (RevenueCat) ─────────────────────────────────
  bool _isPremium = false;
  bool _assinaturaVerificada = false;
  bool get isPremium => _isPremium;
  bool get assinaturaVerificada => _assinaturaVerificada;

  /// Reconsulta o status de assinatura junto ao RevenueCat.
  /// Chame após uma compra, restauração, ou ao reabrir o app.
  Future<void> atualizarStatusAssinatura() async {
    final premium = await SubscriptionService.instance.isPremium();
    _isPremium = premium;
    _assinaturaVerificada = true;
    notifyListeners();
  }

  // ── Cálculos gratuitos (usuário sem assinatura) ─────────────
  // Contador PRÓPRIO, separado do histórico — não pode ser "resetado"
  // apagando itens do histórico, porque só aumenta, nunca diminui.
  int _calculosGratisUsados = 0;
  int get calculosGratisUsados => _calculosGratisUsados;
  int get calculosGratisRestantes =>
      (kLimiteCalculosGratis - _calculosGratisUsados).clamp(0, kLimiteCalculosGratis);

  /// True se o usuário pode fazer mais um cálculo agora (é assinante,
  /// ou ainda não bateu o limite gratuito).
  bool get podeCalcular => _isPremium || _calculosGratisUsados < kLimiteCalculosGratis;

  /// Chame depois de um cálculo bem-sucedido (só tem efeito relevante
  /// para quem não é assinante — para assinantes o contador é ignorado
  /// pela checagem de [podeCalcular], mas seguimos incrementando por
  /// simplicidade/consistência).
  Future<void> registrarCalculoGratis() async {
    if (_isPremium) return;
    _calculosGratisUsados++;
    notifyListeners();
    (await SharedPreferences.getInstance())
        .setInt('calculos_gratis_usados', _calculosGratisUsados);
  }

  List<HistoricoItem> _historico = [];

  bool   _primeiroAcessoConcluido = false;
  String _usuarioNome  = '';
  String _usuarioOab   = '';
  String _usuarioEmail = '';
  bool   _biometriaAtiva = false;

  // Foto de perfil: data URL base64
  String _usuarioFoto  = '';
  // Posição e escala do recorte da foto
  double _fotoOffsetX  = 0.0;
  double _fotoOffsetY  = 0.0;
  double _fotoScale    = 1.0;

  // ── Getters ──────────────────────────────────────────────────
  ModoCalculo get modoCalculo => _modoCalculo;
  ThemeMode   get themeMode   => _themeMode;
  AppTemplate get template    => _template;
  List<HistoricoItem> get historico => List.unmodifiable(_historico);

  bool   get primeiroAcessoConcluido => _primeiroAcessoConcluido;
  String get usuarioNome   => _usuarioNome;
  String get usuarioOab    => _usuarioOab;
  String get usuarioEmail  => _usuarioEmail;
  bool   get biometriaAtiva => _biometriaAtiva;
  String get usuarioFoto   => _usuarioFoto;
  double get fotoOffsetX   => _fotoOffsetX;
  double get fotoOffsetY   => _fotoOffsetY;
  double get fotoScale     => _fotoScale;

  bool _carregado = false;
  bool get carregado => _carregado;

  AppState() { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _modoCalculo = ModoCalculo.values[p.getInt('modo_calculo') ?? 0];
    _themeMode   = ThemeMode.values[p.getInt('theme_mode')    ?? 0];
    _template    = AppTemplate.values[p.getInt('app_template') ?? 0];
    _historico   = (p.getStringList('historico') ?? []).map((s) {
      try { return HistoricoItem.fromJson(json.decode(s)); }
      catch (_) { return null; }
    }).whereType<HistoricoItem>().toList();
    _calculosGratisUsados = p.getInt('calculos_gratis_usados') ?? 0;

    _primeiroAcessoConcluido = p.getBool('primeiro_acesso_ok') ?? false;
    _usuarioNome    = p.getString('usuario_nome')  ?? '';
    _usuarioOab     = p.getString('usuario_oab')   ?? '';
    _usuarioEmail   = p.getString('usuario_email') ?? '';
    _biometriaAtiva = p.getBool('biometria_ativa') ?? false;
    _usuarioFoto    = p.getString('usuario_foto')  ?? '';
    _fotoOffsetX    = p.getDouble('foto_offset_x') ?? 0.0;
    _fotoOffsetY    = p.getDouble('foto_offset_y') ?? 0.0;
    _fotoScale      = p.getDouble('foto_scale')    ?? 1.0;

    _carregado = true;
    notifyListeners();

    // Vincula o RevenueCat/checkout web ao e-mail do usuário (se já
    // conhecido) antes de checar o status de assinatura.
    if (_usuarioEmail.isNotEmpty) {
      await SubscriptionService.instance.identify(_usuarioEmail);
    }

    // Consulta o status de assinatura em paralelo, sem travar a UI.
    atualizarStatusAssinatura();
  }

  Future<void> setModoCalculo(ModoCalculo v) async {
    _modoCalculo = v; notifyListeners();
    (await SharedPreferences.getInstance()).setInt('modo_calculo', v.index);
  }

  Future<void> setThemeMode(ThemeMode v) async {
    _themeMode = v; notifyListeners();
    (await SharedPreferences.getInstance()).setInt('theme_mode', v.index);
  }

  Future<void> setTemplate(AppTemplate v) async {
    _template = v; notifyListeners();
    (await SharedPreferences.getInstance()).setInt('app_template', v.index);
  }

  Future<void> addHistorico(HistoricoItem item) async {
    _historico.insert(0, item);
    if (_historico.length > 100) _historico = _historico.sublist(0, 100);
    notifyListeners();
    await _saveHistorico();
  }

  Future<void> removeHistorico(String id) async {
    _historico.removeWhere((h) => h.id == id);
    notifyListeners(); await _saveHistorico();
  }

  Future<void> limparHistorico() async {
    _historico.clear(); notifyListeners();
    (await SharedPreferences.getInstance()).remove('historico');
  }

  Future<void> _saveHistorico() async {
    (await SharedPreferences.getInstance()).setStringList(
        'historico', _historico.map((h) => json.encode(h.toJson())).toList());
  }

  Future<void> completarPrimeiroAcesso({
    required String nome,
    required String oab,
    required String email,
    required bool biometria,
  }) async {
    _usuarioNome    = nome;
    _usuarioOab     = oab;
    _usuarioEmail   = email;
    _biometriaAtiva = biometria;
    _primeiroAcessoConcluido = true;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('primeiro_acesso_ok', true);
    await p.setString('usuario_nome',  nome);
    await p.setString('usuario_oab',   oab);
    await p.setString('usuario_email', email);
    await p.setBool('biometria_ativa', biometria);

    if (email.isNotEmpty) {
      await SubscriptionService.instance.identify(email);
      await atualizarStatusAssinatura();
    }
  }

  Future<void> setFotoPerfil(String dataUrl) async {
    _usuarioFoto = dataUrl;
    // Resetar posição ao trocar foto
    _fotoOffsetX = 0.0;
    _fotoOffsetY = 0.0;
    _fotoScale   = 1.0;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString('usuario_foto', dataUrl);
    await p.setDouble('foto_offset_x', 0.0);
    await p.setDouble('foto_offset_y', 0.0);
    await p.setDouble('foto_scale',    1.0);
  }

  Future<void> setFotoTransform({
    required double offsetX,
    required double offsetY,
    required double scale,
  }) async {
    _fotoOffsetX = offsetX;
    _fotoOffsetY = offsetY;
    _fotoScale   = scale;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble('foto_offset_x', offsetX);
    await p.setDouble('foto_offset_y', offsetY);
    await p.setDouble('foto_scale',    scale);
  }

  Future<void> resetarPrimeiroAcesso() async {
    _primeiroAcessoConcluido = false;
    _usuarioNome = _usuarioOab = _usuarioEmail = '';
    _biometriaAtiva = false;
    _usuarioFoto = '';
    _fotoOffsetX = _fotoOffsetY = 0.0;
    _fotoScale = 1.0;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    for (final k in ['primeiro_acesso_ok','usuario_nome','usuario_oab',
        'usuario_email','biometria_ativa','usuario_foto',
        'foto_offset_x','foto_offset_y','foto_scale']) {
      await p.remove(k);
    }
  }

  /// Exclui a conta e TODOS os dados do usuário do dispositivo:
  /// perfil, histórico de cálculos, preferências e sessão do Google.
  /// Ação irreversível — usada na tela de Configurações ("Zona de risco").
  Future<void> excluirContaEDados() async {
    // Desloga da conta Google, se houver sessão ativa.
    try {
      await GoogleAuthService.signOut();
    } catch (_) {}

    // Limpa estado em memória.
    _modoCalculo = ModoCalculo.padrao;
    _themeMode   = ThemeMode.system;
    _template    = AppTemplate.navyDourado;
    _historico   = [];
    _primeiroAcessoConcluido = false;
    _usuarioNome = _usuarioOab = _usuarioEmail = '';
    _biometriaAtiva = false;
    _usuarioFoto = '';
    _fotoOffsetX = _fotoOffsetY = 0.0;
    _fotoScale = 1.0;
    notifyListeners();

    // Limpa TODAS as chaves persistidas pelo app.
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
