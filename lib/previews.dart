// lib/previews.dart
// Previews para Flutter Widget Preview (requer Flutter ≥ 3.27).
//
// Como visualizar:
//   1. Abra este arquivo no IDE (VS Code ou Android Studio com extensão Flutter).
//   2. A aba "Widget Preview" mostrará cada @Preview listado abaixo.
//   3. Ou rode: dart run flutter_widget_preview
//
// Cada preview envolve a tela em um ChangeNotifierProvider<AppState>
// e em um MaterialApp para que Provider / Theme / Navigator funcionem.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/primeiro_acesso_screen.dart';
import 'screens/dados_cadastrais_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/projecao_screen.dart';
import 'screens/entre_datas_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/configuracao_screen.dart';

// Tamanhos padrão para previews
const _phone     = Size(402, 874);   // iPhone 14 Pro
const _phoneTall = Size(402, 920);

// ── Wrapper: injeta Provider + MaterialApp + i18n ─────────────────
Widget _wrap(Widget child, {bool scaffolded = false}) {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: Builder(builder: (context) {
      final state = context.watch<AppState>();
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildLight(state.template),
        darkTheme: AppTheme.buildDark(state.template),
        themeMode: state.themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        locale: const Locale('pt', 'BR'),
        home: scaffolded ? Scaffold(body: child) : child,
      );
    }),
  );
}

// ── Fluxo de entrada ─────────────────────────────────────────────

@Preview(name: 'Splash', size: _phone)
Widget previewSplash() =>
    _wrap(const SplashScreen(duration: Duration(seconds: 60)));

@Preview(name: 'Onboarding', size: _phone)
Widget previewOnboarding() => _wrap(const OnboardingScreen());

@Preview(name: 'Primeiro Acesso', size: _phone)
Widget previewPrimeiroAcesso() => _wrap(const PrimeiroAcessoScreen());

// ── Conta / perfil ───────────────────────────────────────────────

@Preview(name: 'Dados Cadastrais', size: _phone)
Widget previewDadosCadastrais() => _wrap(const DadosCadastraisScreen());

// ── Telas principais ─────────────────────────────────────────────

@Preview(name: 'Calculadora · Converter', size: _phoneTall)
Widget previewConverter() => _wrap(const ConverterScreen(), scaffolded: true);

@Preview(name: 'Projeção de data', size: _phoneTall)
Widget previewProjecao() => _wrap(const ProjecaoScreen(), scaffolded: true);

@Preview(name: 'Entre datas', size: _phoneTall)
Widget previewEntreDatas() => _wrap(const EntreDatasScreen(), scaffolded: true);

@Preview(name: 'Histórico', size: _phoneTall)
Widget previewHistorico() => _wrap(const HistoricoScreen(), scaffolded: true);

@Preview(name: 'Configurações', size: _phoneTall)
Widget previewConfiguracao() => _wrap(const ConfiguracaoScreen(), scaffolded: true);

// ── Variações de tema ────────────────────────────────────────────

@Preview(name: 'Configurações · Dark', size: _phoneTall, brightness: Brightness.dark)
Widget previewConfiguracaoDark() =>
    _wrap(const ConfiguracaoScreen(), scaffolded: true);

@Preview(name: 'Onboarding · Light', size: _phone, brightness: Brightness.light)
Widget previewOnboardingLight() => _wrap(const OnboardingScreen());
