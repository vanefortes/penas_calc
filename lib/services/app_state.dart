// lib/services/app_state.dart
// Adicionados: flag de primeiro acesso + perfil do usuário.

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

  // ───── NOVO: primeiro acesso / perfil ─────
  bool   _primeiroAcessoConcluido = false;
  String _usuarioNome = '';
  String _usuarioOab  = '';
  String _usuarioEmail = '';
  bool   _biometriaAtiva = false;

  ModoCalculo get modoCalculo => _modoCalculo;
  ThemeMode   get themeMode   => _themeMode;
  AppTemplate get template    => _template;
  List<HistoricoItem> get historico => List.unmodifiable(_historico);

  bool   get primeiroAcessoConcluido => _primeiroAcessoConcluido;
  String get usuarioNome  => _usuarioNome;
  String get usuarioOab   => _usuarioOab;
  String get usuarioEmail => _usuarioEmail;
  bool   get biometriaAtiva => _biometriaAtiva;

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
    await _save();
  }

  Future<void> removeHistorico(String id) async {
    _historico.removeWhere((h) => h.id == id);
    notifyListeners(); await _save();
  }

  Future<void> limparHistorico() async {
    _historico.clear(); notifyListeners();
    (await SharedPreferences.getInstance()).remove('historico');
  }

  Future<void> _save() async {
    (await SharedPreferences.getInstance()).setStringList(
        'historico', _historico.map((h) => json.encode(h.toJson())).toList());
  }

  // ───── NOVO: primeiro acesso ─────
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

  Future<void> resetarPrimeiroAcesso() async {
    _primeiroAcessoConcluido = false;
    _usuarioNome = _usuarioOab = _usuarioEmail = '';
    _biometriaAtiva = false;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove('primeiro_acesso_ok');
    await p.remove('usuario_nome');
    await p.remove('usuario_oab');
    await p.remove('usuario_email');
    await p.remove('biometria_ativa');
  }
}
