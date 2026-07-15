import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/app_state.dart';
import 'services/firebase_auth_service.dart';
import 'theme/app_theme.dart';
import 'models/calculo.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';          // ← NOVO
import 'screens/primeiro_acesso_screen.dart';     // ← NOVO
import 'screens/converter_screen.dart';
import 'screens/projecao_screen.dart';
import 'screens/entre_datas_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/configuracao_screen.dart';
import 'screens/dados_cadastrais_screen.dart';
import 'screens/editar_cadastro_screen.dart';
import 'screens/editor_foto_screen.dart';
import 'screens/lock_screen.dart';
import 'services/subscription_service.dart';
import 'services/google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SubscriptionService.instance.init();
  await GoogleAuthService.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const CalcPenasApp(),
    ),
  );
}

class CalcPenasApp extends StatelessWidget {
  const CalcPenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Calculadora Penal',
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

      // ───── Splash → Onboarding (1º acesso) → MainShell ─────
      home: const SplashScreen(
        nextRoute: AppEntry(),
        duration: Duration(milliseconds: 2800),
      ),
      routes: {
        '/home': (_) => const MainShell(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/primeiro-acesso': (_) => const PrimeiroAcessoScreen(),
      },
    );
  }
}

/// Decide o que mostrar após a splash:
/// — se já fez primeiro acesso, vai direto para MainShell
/// — caso contrário, mostra o Onboarding.
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Aguarda carregar os dados do SharedPreferences
    if (!state.carregado) {
      return const Scaffold(
        backgroundColor: Color(0xFF050A18),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC9A961)),
        ),
      );
    }

    if (!state.primeiroAcessoConcluido) return const OnboardingScreen();

    // Revalida que a sessão do Firebase ainda existe antes de liberar o
    // app — usa o stream (não `currentUser` direto), porque o Firebase
    // pode levar um instante para restaurar uma sessão já salva ao abrir
    // o app. Checar `currentUser` cedo demais daria um "falso positivo"
    // de sessão perdida para quem já estava logado.
    return StreamBuilder<User?>(
      stream: FirebaseAuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF050A18),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC9A961)),
            ),
          );
        }

        if (snapshot.data == null) {
          // A sessão do Firebase não existe (ou foi perdida por algum
          // motivo, ex: revogação) — volta direto pro login, sem repetir
          // os slides de onboarding (que são só para quem nunca usou o
          // app).
          return const PrimeiroAcessoScreen();
        }

        // Aguarda a primeira consulta de status de assinatura antes de
        // decidir se mostra o paywall, para não "piscar" a tela de
        // bloqueio à toa.
        if (!state.assinaturaVerificada) {
          return const Scaffold(
            backgroundColor: Color(0xFF050A18),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC9A961)),
            ),
          );
        }

        if (state.biometriaAtiva) {
          return LockScreen(child: const MainShell());
        }

        return const MainShell();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _titles = [
    'Calculadora Penal',
    'Projeção de data',
    'Entre datas',
    'Histórico',
    'Configurações',
  ];

  final _screens = const [
    ConverterScreen(),
    ProjecaoScreen(),
    EntreDatasScreen(),
    HistoricoScreen(),
    _ConfigShell(), // ← Navigator interno para Config + Dados Cadastrais
  ];

  @override
  Widget build(BuildContext context) {
    final modo = context.watch<AppState>().modoCalculo;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.gavel_rounded, size: 20),
          const SizedBox(width: 10),
          Text(_titles[_currentIndex]),
        ]),
        actions: [
          if (_currentIndex < 3)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _ModoPill(modo: modo),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: Theme.of(context)
                .appBarTheme
                .foregroundColor
                ?.withOpacity(0.2),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          const _Rodape(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Converter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_rounded),
            label: 'Projeção',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range_rounded),
            label: 'Datas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Config.',
          ),
        ],
      ),
    );
  }
}

/// Navigator interno para a aba de Configurações.
/// Permite navegar entre ConfiguracaoScreen ↔ DadosCadastraisScreen
/// ↔ EditarCadastroScreen sem sair do MainShell.
class _ConfigShell extends StatelessWidget {
  const _ConfigShell();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/dados-cadastrais':
            page = const DadosCadastraisScreen();
            break;
          case '/editar-cadastro':
            page = const EditarCadastroScreen();
            break;
          case '/editor-foto':
            page = const EditorFotoScreen();
            break;
          default:
            page = const ConfiguracaoScreen();
        }
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}

class _ModoPill extends StatelessWidget {
  final ModoCalculo modo;
  const _ModoPill({required this.modo});

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return GestureDetector(
      onTap: () {
        final state = context.read<AppState>();
        final next = ModoCalculo
            .values[(modo.index + 1) % ModoCalculo.values.length];
        state.setModoCalculo(next);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Modo: ${next.nome}',
              style: GoogleFonts.inter(fontSize: 13)),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ));
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fg?.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: fg?.withOpacity(0.3) ?? Colors.white30,
              width: 0.5),
        ),
        child: Text(
          modo.nome,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: fg?.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape();

  @override
  Widget build(BuildContext context) {
    final ano = DateTime.now().year;
    final fg = Theme.of(context).appBarTheme.foregroundColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: fg?.withOpacity(0.2) ??
                Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Copyright © $ano V Fortttes Inc.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
