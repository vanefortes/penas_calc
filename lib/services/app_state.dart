// lib/services/app_state.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculo.dart';
import '../theme/app_theme.dart';

class AppState extends ChangeNotifier {
  ModoCalculo _modoCalculo = ModoCalculo.padrao;
  ThemeMode   _themeMode   = ThemeMode.system;
  AppTemplate _template    = AppTemplate.navyDourado;
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
}
