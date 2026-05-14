// lib/screens/onboarding_screen.dart
// Onboarding (3 telas) — Calculadora Penal
// Mesma identidade da Splash: navy + ouro gravado.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import 'primeiro_acesso_screen.dart';

class _CP {
  static const navyDeep   = Color(0xFF050A18);
  static const navy       = Color(0xFF0B1530);
  static const navyCard   = Color(0xFF13213D);
  static const gold       = Color(0xFFC9A961);
  static const goldBright = Color(0xFFF0D488);
  static const goldDeep   = Color(0xFF7A6230);
  static const cyanGlow   = Color(0xFF7CC4FF);
  static const textDim    = Color(0x9EE8DEC4);
  static const textFaint  = Color(0x57E8DEC4);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  static const _slides = [
    _SlideData(
      eyebrow: '01 / 03',
      title: 'Dosimetria com precisão jurídica',
      body: 'Cálculo trifásico, regime de pena, detração, remição e prescrição em uma única ferramenta.',
      icon: Icons.balance_rounded,
    ),
    _SlideData(
      eyebrow: '02 / 03',
      title: 'Progressão e datas-chave automatizadas',
      body: 'Projete a próxima progressão, livramento condicional e marcos do cumprimento sem esforço manual.',
      icon: Icons.stairs_rounded,
    ),
    _SlideData(
      eyebrow: '03 / 03',
      title: 'Seus cálculos, protegidos',
      body: 'Histórico salvo localmente, exportação em PDF e proteção biométrica. Nada sai do seu dispositivo.',
      icon: Icons.shield_moon_rounded,
    ),
  ];

  void _next() {
    if (_i < _slides.length - 1) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goPrimeiroAcesso();
    }
  }

  void _goPrimeiroAcesso() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: a,
        child: const PrimeiroAcessoScreen(),
      ),
    ));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _CP.navyDeep,
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              child: Column(
                children: [
                  // top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('C · P',
                          style: GoogleFonts.cinzel(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            letterSpacing: 11 * 0.28, color: _CP.goldBright,
                          )),
                        TextButton(
                          onPressed: _goPrimeiroAcesso,
                          style: TextButton.styleFrom(
                            foregroundColor: _CP.textDim,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Pular',
                            style: GoogleFonts.inter(
                              fontSize: 13, color: _CP.textDim,
                              letterSpacing: 0.04,
                            )),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      onPageChanged: (i) => setState(() => _i = i),
                      itemCount: _slides.length,
                      itemBuilder: (_, i) => _Slide(data: _slides[i]),
                    ),
                  ),
                  // indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (k) {
                        final active = k == _i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: active
                                ? const LinearGradient(colors: [_CP.goldDeep, _CP.goldBright])
                                : null,
                            color: active ? null : const Color(0x2EE8DEC4),
                            boxShadow: active
                                ? const [BoxShadow(color: _CP.gold, blurRadius: 6)]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                  // CTA
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _GoldButton(
                      label: _i == _slides.length - 1 ? 'COMEÇAR' : 'CONTINUAR',
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String eyebrow, title, body;
  final IconData icon;
  const _SlideData({required this.eyebrow, required this.title, required this.body, required this.icon});
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _GlowIcon(child: Icon(data.icon, size: 58, color: _CP.goldBright)),
          const SizedBox(height: 36),
          Text(data.eyebrow,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10, letterSpacing: 10 * 0.32,
              color: _CP.goldBright,
            )),
          const SizedBox(height: 10),
          Text(data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 26, fontWeight: FontWeight.w600,
              height: 1.18, color: const Color(0xFFF3EEDB),
              letterSpacing: 0.26,
            )),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(data.body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14, height: 1.55, color: _CP.textDim,
              )),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  final Widget child;
  const _GlowIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170, height: 170,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 170, height: 170,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              Color(0x527CC4FF), Color(0x1C7CC4FF), Colors.transparent,
            ], stops: [0, 0.5, 0.8]),
          ),
        ),
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_CP.navyCard, _CP.navyDeep],
            ),
            border: Border.all(color: _CP.goldDeep, width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x33F0D488), blurRadius: 16, spreadRadius: -8),
            ],
          ),
        ),
        child,
      ]),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_CP.goldBright, _CP.goldDeep],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x73C9A961), blurRadius: 14, offset: Offset(0, 4)),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(label,
              style: GoogleFonts.cinzel(
                fontSize: 14, fontWeight: FontWeight.w700,
                letterSpacing: 14 * 0.16, color: _CP.navyDeep,
              )),
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_CP.navy, _CP.navyDeep],
          ),
        ),
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.05),
            radius: 0.85,
            colors: [Color(0x247CC4FF), Colors.transparent],
          ),
        ),
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, 1.1),
            radius: 0.95,
            colors: [Color(0x66143468), Colors.transparent],
          ),
        ),
      ),
    ]);
  }
}
