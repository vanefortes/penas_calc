// lib/preview_helpers.dart
// Wrapper para anotações @Preview — injeta ChangeNotifierProvider<AppState>
// + MaterialApp com theme/i18n. Cada tela usa via:
//
//   @Preview(name: 'Minha Tela')
//   Widget previewMinhaTela() => previewWrap(const MinhaTela(), scaffolded: true);

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

/// Envolve [child] em Provider + MaterialApp para Widget Preview funcionar.
/// Passe `scaffolded: true` para telas internas que esperam um Scaffold
/// (ex.: converter, projeção). Splash/onboarding já trazem o próprio Scaffold.
Widget previewWrap(Widget child, {bool scaffolded = false}) {
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
