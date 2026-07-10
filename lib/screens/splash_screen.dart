// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CpColors {
  static const navy       = Color(0xFF0B1530);
  static const navyDeep   = Color(0xFF050A18);
  static const gold       = Color(0xFFC9A961);
  static const goldBright = Color(0xFFF0D488);
  static const goldDeep   = Color(0xFF7A6230);
  static const cyanGlow   = Color(0xFF7CC4FF);
  static const textDim    = Color(0x9EE8DEC4);
  static const textFaint  = Color(0x57E8DEC4);
}

class SplashScreen extends StatefulWidget {
  final Widget? nextRoute;
  final Duration duration;
  const SplashScreen({super.key, this.nextRoute, this.duration = const Duration(milliseconds: 2800)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _sway;
  late final AnimationController _float;
  late final AnimationController _aura;
  late final AnimationController _ring;
  late final AnimationController _ringRev;
  late final AnimationController _intro;
  late final AnimationController _bar;

  @override
  void initState() {
    super.initState();
    _sway    = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat(reverse: true);
    _float   = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat(reverse: true);
    _aura    = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _ring    = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();
    _ringRev = AnimationController(vsync: this, duration: const Duration(seconds: 36))..repeat();
    _intro   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _bar     = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);

    if (widget.nextRoute != null) {
      Future.delayed(widget.duration, () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: widget.nextRoute!),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_sway, _float, _aura, _ring, _ringRev, _intro, _bar]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CpColors.navyDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _BackgroundLayer(),
          _CornerOrnaments(),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  // Emblema adaptável: máximo 42% da altura disponível
                  final emblemSize = (h * 0.42).clamp(140.0, 320.0);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: emblemSize,
                        height: emblemSize,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: _Emblem(
                            sway: _sway, floaty: _float, aura: _aura,
                            ring: _ring, ringRev: _ringRev, intro: _intro,
                          ),
                        ),
                      ),
                      SizedBox(height: (h * 0.03).clamp(8.0, 24.0)),
                      const _TitleBlock(),
                      SizedBox(height: (h * 0.04).clamp(8.0, 36.0)),
                      _LoadingBar(controller: _bar),
                    ],
                  );
                },
              ),
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 36, child: _Footer()),
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 100, spreadRadius: -40)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(decoration: const BoxDecoration(gradient: RadialGradient(
        center: Alignment(0, -0.2), radius: 1.1,
        colors: [Color(0xFF142447), CpColors.navyDeep],
      ))),
      Container(decoration: const BoxDecoration(gradient: RadialGradient(
        center: Alignment(0.6, -0.9), radius: 0.9,
        colors: [Color(0x1FC9A961), Colors.transparent],
      ))),
      Container(decoration: const BoxDecoration(gradient: RadialGradient(
        center: Alignment(0, -0.2), radius: 0.7,
        colors: [Color(0x2E7CC4FF), Colors.transparent],
      ))),
      Opacity(opacity: 0.22, child: CustomPaint(painter: _CircuitPainter())),
      const _LegalFragments(),
    ]);
  }
}

class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = CpColors.gold.withOpacity(0.55)..strokeWidth = 0.4..style = PaintingStyle.stroke;
    final dot  = Paint()..color = CpColors.gold.withOpacity(0.8);
    const tile = 58.0;
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        final p = Path()
          ..moveTo(x, y+29)..lineTo(x+18, y+29)..lineTo(x+23, y+24)..lineTo(x+33, y+24)
          ..lineTo(x+38, y+29)..lineTo(x+58, y+29)
          ..moveTo(x+29, y)..lineTo(x+29, y+16)
          ..moveTo(x+29, y+42)..lineTo(x+29, y+58);
        canvas.drawPath(p, line);
        canvas.drawCircle(Offset(x+29, y+29), 1.3, dot);
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LegalFragments extends StatelessWidget {
  const _LegalFragments();
  static const _frags = [
    _Frag(36, 200, 'Art. 59 — O juiz, atendendo à culpabilidade,'),
    _Frag(40, 218, 'aos antecedentes, à conduta social...'),
    _Frag(230, 240, 'Art. 33 § 2º — As penas privativas'),
    _Frag(240, 258, 'de liberdade deverão ser executadas'),
    _Frag(32, 430, 'Art. 112 — A pena privativa de'),
    _Frag(36, 448, 'liberdade será executada em forma'),
    _Frag(228, 470, 'Art. 109 — A prescrição,'),
    _Frag(236, 488, 'antes de transitar em julgado a sentença'),
  ];
  @override
  Widget build(BuildContext context) => Stack(children: [
    for (final f in _frags)
      Positioned(left: f.x, top: f.y,
        child: Text(f.t, style: GoogleFonts.cormorantGaramond(
          fontStyle: FontStyle.italic, fontSize: 11, color: const Color(0x1AE8DEC4)))),
  ]);
}

class _Frag { final double x, y; final String t; const _Frag(this.x, this.y, this.t); }

class _Emblem extends StatelessWidget {
  final AnimationController sway, floaty, aura, ring, ringRev, intro;
  const _Emblem({required this.sway, required this.floaty, required this.aura,
                 required this.ring, required this.ringRev, required this.intro});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: intro, builder: (_, __) {
      final t = Curves.easeOutBack.transform(intro.value.clamp(0, 1));
      return Transform.scale(scale: 0.7 + 0.3 * t,
        child: Opacity(opacity: intro.value, child: _stack()));
    });
  }
  Widget _stack() => SizedBox(width: 320, height: 330,
    child: Stack(alignment: Alignment.center, children: [
      RotationTransition(turns: ring,
        child: Opacity(opacity: 0.5, child: CustomPaint(size: const Size(320, 320),
          painter: _DashedCirclePainter(radius: 148, color: CpColors.gold, dash: 2, gap: 8, width: 0.6)))),
      RotationTransition(turns: ReverseAnimation(ringRev),
        child: Opacity(opacity: 0.4, child: CustomPaint(size: const Size(260, 260),
          painter: _DashedCirclePainter(radius: 120, color: CpColors.cyanGlow, dash: 1, gap: 10, width: 0.5)))),
      AnimatedBuilder(animation: aura, builder: (_, __) {
        final v = 0.55 + 0.45 * aura.value;
        return Opacity(opacity: v, child: Transform.scale(scale: 1 + 0.15 * aura.value,
          child: Container(width: 240, height: 240, decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              CpColors.cyanGlow.withOpacity(0.45), CpColors.cyanGlow.withOpacity(0.12), Colors.transparent,
            ], stops: const [0, 0.4, 0.7])))));
      }),
      AnimatedBuilder(animation: aura, builder: (_, __) {
        final v = 0.6 + 0.4 * (1 - aura.value);
        return Opacity(opacity: v, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [CpColors.goldBright.withOpacity(0.22), Colors.transparent]))));
      }),
      _Particles(controller: ring),
      _Sparkles(),
      AnimatedBuilder(animation: Listenable.merge([sway, floaty]), builder: (_, __) {
        final swayDeg = (-2.2 + 4.4 * sway.value) * math.pi / 180;
        final dy = -6 * floaty.value;
        return Transform.translate(offset: Offset(0, dy),
          child: Transform(alignment: const Alignment(0, -0.92),
            transform: Matrix4.rotationZ(swayDeg),
            child: Image.asset('assets/logo.png', width: 280, fit: BoxFit.contain)));
      }),
    ]));
}

class _DashedCirclePainter extends CustomPainter {
  final double radius, dash, gap, width; final Color color;
  _DashedCirclePainter({required this.radius, required this.color, required this.dash, required this.gap, required this.width});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color..strokeWidth = width..style = PaintingStyle.stroke;
    final circ = 2 * math.pi * radius;
    final n = (circ / (dash + gap)).floor();
    for (int i = 0; i < n; i++) {
      final a0 = (i * (dash + gap)) / radius;
      final a1 = (i * (dash + gap) + dash) / radius;
      canvas.drawArc(Rect.fromCircle(center: c, radius: radius), a0, a1 - a0, false, paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Particles extends StatelessWidget {
  final AnimationController controller;
  const _Particles({required this.controller});
  @override
  Widget build(BuildContext context) {
    final motes = List.generate(14, (i) {
      final rnd = math.Random(i);
      return _Mote(x: 90 + rnd.nextDouble() * 110, delay: (i * 0.4) % 5,
        dur: 3.6 + rnd.nextDouble() * 2.4, r: 1 + rnd.nextDouble() * 1.8,
        color: i % 3 == 0 ? CpColors.goldBright : CpColors.cyanGlow);
    });
    return AnimatedBuilder(animation: controller, builder: (_, __) {
      final time = controller.value * 28;
      return Stack(children: motes.map((m) {
        final phase = ((time - m.delay) / m.dur) % 1;
        if (phase < 0) return const SizedBox.shrink();
        final opacity = phase < 0.3 ? phase / 0.3 : 1 - (phase - 0.3) / 0.7;
        return Positioned(left: m.x, bottom: 60 + phase * 90,
          child: Opacity(opacity: opacity.clamp(0, 1).toDouble(),
            child: Container(width: m.r * 2, height: m.r * 2,
              decoration: BoxDecoration(shape: BoxShape.circle, color: m.color,
                boxShadow: [BoxShadow(color: m.color, blurRadius: m.r * 4)]))));
      }).toList());
    });
  }
}

class _Mote {
  final double x, delay, dur, r; final Color color;
  _Mote({required this.x, required this.delay, required this.dur, required this.r, required this.color});
}

class _Sparkles extends StatefulWidget {
  @override State<_Sparkles> createState() => _SparklesState();
}
class _SparklesState extends State<_Sparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  static const _sparks = [[18.0,80.0,0.0,1.0],[262.0,120.0,0.6,1.3],[46.0,230.0,1.2,0.9],[240.0,250.0,1.8,1.1],[140.0,30.0,2.4,1.0]];
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _c, builder: (_, __) {
      final t = _c.value * 2.4;
      return Stack(children: _sparks.map((s) {
        final phase = ((t - s[2]) / 2.4) % 1;
        final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
        return Positioned(left: s[0], top: s[1],
          child: Opacity(opacity: opacity, child: Transform.scale(scale: (0.4 + 0.6 * opacity) * s[3],
            child: const Icon(Icons.star, color: CpColors.goldBright, size: 14))));
      }).toList());
    });
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();
  Widget _gradientText(String t, {double letter = 0.04}) => ShaderMask(
    shaderCallback: (r) => const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF4D0), CpColors.goldBright, CpColors.gold, CpColors.goldDeep],
      stops: [0, 0.35, 0.7, 1],
    ).createShader(r),
    child: Text(t, style: GoogleFonts.cinzel(
      fontWeight: FontWeight.w700, fontSize: 34, color: Colors.white,
      letterSpacing: 34 * letter, height: 1.05)),
  );
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _gradientText('CALCULADORA'),
      const SizedBox(height: 2),
      _gradientText('PENAL', letter: 0.18),
      const SizedBox(height: 14),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 1, width: 42, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, CpColors.gold]))),
        const SizedBox(width: 10),
        const Icon(Icons.auto_awesome, size: 12, color: CpColors.goldBright),
        const SizedBox(width: 10),
        Container(height: 1, width: 42, decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [CpColors.gold, Colors.transparent]))),
      ]),
      const SizedBox(height: 10),
      Text('Sua aliada na precisão jurídica.',
        style: GoogleFonts.cormorantGaramond(fontStyle: FontStyle.italic, fontSize: 15, color: const Color(0xFFE8DEC4))),
    ]);
  }
}

class _LoadingBar extends StatelessWidget {
  final AnimationController controller;
  const _LoadingBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70),
      child: Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(99),
          child: Container(height: 3,
            decoration: BoxDecoration(color: const Color(0x8C000000),
              border: Border.all(color: CpColors.goldDeep, width: 0.5),
              borderRadius: BorderRadius.circular(99)),
            child: AnimatedBuilder(animation: controller, builder: (_, __) {
              return Align(alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: controller.value * 0.78,
                  child: Container(decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [CpColors.goldDeep, CpColors.goldBright]),
                    boxShadow: [BoxShadow(color: CpColors.gold, blurRadius: 8)]))));
            }))),
        const SizedBox(height: 12),
        Text('CARREGANDO...', style: GoogleFonts.jetBrainsMono(
          fontSize: 11, color: CpColors.textDim, letterSpacing: 11 * 0.32)),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final ano = DateTime.now().year;
    return Column(children: [
      Text('Copyright © $ano V Fortttes Inc.', style: GoogleFonts.cormorantGaramond(fontSize: 12, color: CpColors.textFaint)),
      const SizedBox(height: 4),
      Text('Todos os direitos reservados', style: GoogleFonts.cinzel(
          fontWeight: FontWeight.w500, fontSize: 11, color: CpColors.textDim, letterSpacing: 11 * 0.22)),
    ]);
  }
}

class _CornerOrnaments extends StatelessWidget {
  Widget _arm({bool flipX = false, bool flipY = false}) => Transform(
    alignment: Alignment.center,
    transform: Matrix4.diagonal3Values(flipX ? -1 : 1, flipY ? -1 : 1, 1),
    child: SizedBox(width: 46, height: 46, child: CustomPaint(painter: _OrnamentPainter())));
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned(top: 54, left: 14,     child: _arm()),
    Positioned(top: 54, right: 14,    child: _arm(flipX: true)),
    Positioned(bottom: 14, left: 14,  child: _arm(flipY: true)),
    Positioned(bottom: 14, right: 14, child: _arm(flipX: true, flipY: true)),
  ]);
}

class _OrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = CpColors.gold.withOpacity(0.7)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(2, 2), const Offset(20, 2), p);
    canvas.drawLine(const Offset(2, 2), const Offset(2, 20), p);
    canvas.drawLine(const Offset(2, 2), const Offset(14, 14), p);
    final dot = Paint()..color = CpColors.goldBright;
    canvas.drawCircle(const Offset(20, 2), 1.4, dot);
    canvas.drawCircle(const Offset(2, 20), 1.4, dot);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}
