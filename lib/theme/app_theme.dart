import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTemplate { navyDourado, verdeMosgoDourado, vinhoDourado, cinzaChumbo, preto, beigeMarrom }

extension AppTemplateExt on AppTemplate {
  String get nome {
    switch (this) {
      case AppTemplate.navyDourado:       return 'Navy & Dourado';
      case AppTemplate.verdeMosgoDourado: return 'Verde Musgo & Dourado';
      case AppTemplate.vinhoDourado:      return 'Vinho & Dourado';
      case AppTemplate.cinzaChumbo:       return 'Cinza Chumbo';
      case AppTemplate.preto:             return 'Preto';
      case AppTemplate.beigeMarrom:       return 'Bege & Marrom';
    }
  }

  String get descricao {
    switch (this) {
      case AppTemplate.navyDourado:       return 'Azul marinho com detalhes dourados';
      case AppTemplate.verdeMosgoDourado: return 'Verde musgo escuro com dourado e bronze';
      case AppTemplate.vinhoDourado:      return 'Bordô elegante com dourado e bronze';
      case AppTemplate.cinzaChumbo:       return 'Cinza chumbo sofisticado';
      case AppTemplate.preto:             return 'Preto clássico e imponente';
      case AppTemplate.beigeMarrom:       return 'Bege e marrom · estilo jurídico tradicional';
    }
  }

  Color get corPrimaria {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFF0D1B3E);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFF2D4A1E);
      case AppTemplate.vinhoDourado:      return const Color(0xFF5C0A2E);
      case AppTemplate.cinzaChumbo:       return const Color(0xFF2E3338);
      case AppTemplate.preto:             return const Color(0xFF0A0A0A);
      case AppTemplate.beigeMarrom:       return const Color(0xFF5C3A1E);
    }
  }

  Color get corAcento {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFFCFA82C);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFFB8860B);
      case AppTemplate.vinhoDourado:      return const Color(0xFFCDA135);
      case AppTemplate.cinzaChumbo:       return const Color(0xFF8A9199);
      case AppTemplate.preto:             return const Color(0xFF888888);
      case AppTemplate.beigeMarrom:       return const Color(0xFF8B5E3C);
    }
  }

  Color get corFundo {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFFEEF1F8);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFFEEF2E8);
      case AppTemplate.vinhoDourado:      return const Color(0xFFF5EEF0);
      case AppTemplate.cinzaChumbo:       return const Color(0xFFEEEFF0);
      case AppTemplate.preto:             return const Color(0xFFF0F0F0);
      case AppTemplate.beigeMarrom:       return const Color(0xFFF5EDD8);
    }
  }

  Color get corPrimariaEscura {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFFCFA82C);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFFB8D68A);
      case AppTemplate.vinhoDourado:      return const Color(0xFFE8A0B0);
      case AppTemplate.cinzaChumbo:       return const Color(0xFFB0B8C1);
      case AppTemplate.preto:             return const Color(0xFFE0E0E0);
      case AppTemplate.beigeMarrom:       return const Color(0xFFE8C99A);
    }
  }

  Color get corAcentoEscura {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFF4A6FA5);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFFB8860B);
      case AppTemplate.vinhoDourado:      return const Color(0xFFCDA135);
      case AppTemplate.cinzaChumbo:       return const Color(0xFF5C6670);
      case AppTemplate.preto:             return const Color(0xFF666666);
      case AppTemplate.beigeMarrom:       return const Color(0xFFB8860B);
    }
  }

  Color get corFundoEscura {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFF060D1E);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFF0A140A);
      case AppTemplate.vinhoDourado:      return const Color(0xFF1A0510);
      case AppTemplate.cinzaChumbo:       return const Color(0xFF111314);
      case AppTemplate.preto:             return const Color(0xFF000000);
      case AppTemplate.beigeMarrom:       return const Color(0xFF1A1008);
    }
  }

  Color get corCardEscura {
    switch (this) {
      case AppTemplate.navyDourado:       return const Color(0xFF0D1B3E);
      case AppTemplate.verdeMosgoDourado: return const Color(0xFF152510);
      case AppTemplate.vinhoDourado:      return const Color(0xFF2A0A1A);
      case AppTemplate.cinzaChumbo:       return const Color(0xFF1C2025);
      case AppTemplate.preto:             return const Color(0xFF141414);
      case AppTemplate.beigeMarrom:       return const Color(0xFF241508);
    }
  }
}

class AppTheme {
  static ThemeData buildLight(AppTemplate t) {
    final p = t.corPrimaria; final a = t.corAcento;
    final bg = t.corFundo;
    final title = _titleFont(t); final text = _textFont(t);
    return ThemeData(
      useMaterial3: true, brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: p, onPrimary: Colors.white,
        secondary: a, onSecondary: Colors.white,
        surface: Colors.white, onSurface: p,
        error: const Color(0xFFE24B4A), onError: Colors.white,
        surfaceContainerHighest: bg,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: p, foregroundColor: a, elevation: 0, centerTitle: false,
        titleTextStyle: title.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: a),
        iconTheme: IconThemeData(color: a), surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.withOpacity(0.15), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: p.withOpacity(0.25), width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: p.withOpacity(0.25), width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: a, width: 1.5)),
        labelStyle: text.copyWith(fontSize: 13, color: p.withOpacity(0.6)),
        hintStyle: text.copyWith(fontSize: 14, color: p.withOpacity(0.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p, foregroundColor: a, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p, side: BorderSide(color: p.withOpacity(0.35), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: a, unselectedLabelColor: a.withOpacity(0.5),
        indicatorColor: a, indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: text.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: text.copyWith(fontSize: 13),
        dividerColor: a.withOpacity(0.2),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p, selectedItemColor: a,
        unselectedItemColor: a.withOpacity(0.45),
        selectedLabelStyle: text.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: text.copyWith(fontSize: 11),
        elevation: 8, type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(color: p.withOpacity(0.12), thickness: 0.5, space: 0),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? p : Colors.transparent),
        checkColor: WidgetStateProperty.all(a),
        side: BorderSide(color: p.withOpacity(0.4), width: 1.5),
      ),
      textTheme: _buildTextTheme(text, title, p),
    );
  }

  static ThemeData buildDark(AppTemplate t) {
    final p = t.corPrimariaEscura; final a = t.corAcentoEscura;
    final bg = t.corFundoEscura; final card = t.corCardEscura;
    final title = _titleFont(t); final text = _textFont(t);
    return ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: p, onPrimary: Colors.black,
        secondary: a, onSecondary: Colors.black,
        surface: card, onSurface: p,
        error: const Color(0xFFF09595), onError: const Color(0xFF501313),
        surfaceContainerHighest: bg,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: card, foregroundColor: p, elevation: 0, centerTitle: false,
        titleTextStyle: title.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: p),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.withOpacity(0.15), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: p.withOpacity(0.25), width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: p.withOpacity(0.25), width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: p, width: 1.5)),
        labelStyle: text.copyWith(fontSize: 13, color: p.withOpacity(0.6)),
        hintStyle: text.copyWith(fontSize: 14, color: p.withOpacity(0.35)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p, foregroundColor: Colors.black, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p, side: BorderSide(color: p.withOpacity(0.35), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p, unselectedLabelColor: p.withOpacity(0.45),
        indicatorColor: p, indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: text.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: text.copyWith(fontSize: 13),
        dividerColor: p.withOpacity(0.15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card, selectedItemColor: p,
        unselectedItemColor: p.withOpacity(0.4),
        selectedLabelStyle: text.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: text.copyWith(fontSize: 11),
        elevation: 8, type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(color: p.withOpacity(0.15), thickness: 0.5, space: 0),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? p : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: BorderSide(color: p.withOpacity(0.4), width: 1.5),
      ),
      textTheme: _buildTextTheme(text, title, p),
    );
  }

  static TextTheme _buildTextTheme(TextStyle text, TextStyle title, Color p) => TextTheme(
    displayLarge:   title.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: p),
    headlineLarge:  title.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: p),
    headlineMedium: title.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: p),
    titleLarge:     text.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: p),
    titleMedium:    text.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: p),
    titleSmall:     text.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: p),
    bodyLarge:      text.copyWith(fontSize: 15, color: p),
    bodyMedium:     text.copyWith(fontSize: 14, color: p),
    bodySmall:      text.copyWith(fontSize: 13, color: p.withOpacity(0.6)),
    labelSmall:     text.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: p.withOpacity(0.45)),
  );

  static TextStyle _titleFont(AppTemplate t) {
    switch (t) {
      case AppTemplate.navyDourado:       return GoogleFonts.cinzel();
      case AppTemplate.verdeMosgoDourado: return GoogleFonts.playfairDisplay();
      case AppTemplate.vinhoDourado:      return GoogleFonts.cormorantGaramond();
      case AppTemplate.cinzaChumbo:       return GoogleFonts.rajdhani();
      case AppTemplate.preto:             return GoogleFonts.dmSans();
      case AppTemplate.beigeMarrom:       return GoogleFonts.playfairDisplay();
    }
  }

  static TextStyle _textFont(AppTemplate t) {
    switch (t) {
      case AppTemplate.navyDourado:       return GoogleFonts.inter();
      case AppTemplate.verdeMosgoDourado: return GoogleFonts.inter();
      case AppTemplate.vinhoDourado:      return GoogleFonts.inter();
      case AppTemplate.cinzaChumbo:       return GoogleFonts.inter();
      case AppTemplate.preto:             return GoogleFonts.dmSans();
      case AppTemplate.beigeMarrom:       return GoogleFonts.sourceSerif4();
    }
  }

  static Color accentColor(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color accentBg(BuildContext context) => accentColor(context)
      .withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.1);
  static Color dangerColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF09595) : const Color(0xFFE24B4A);
  static Color dangerBg(BuildContext context) => dangerColor(context).withOpacity(0.12);
  static Color warningColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF0A030) : const Color(0xFFBA7517);
  static Color warningBg(BuildContext context) => warningColor(context).withOpacity(0.12);
  static Color infoColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF85B7EB) : const Color(0xFF185FA5);
  static Color infoBg(BuildContext context) => infoColor(context).withOpacity(0.12);
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
}