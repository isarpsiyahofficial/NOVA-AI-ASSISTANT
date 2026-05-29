// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum NovaOrbState { idle, listening, speaking, sleeping, fullyOff }

class NovaCoreOrb extends StatefulWidget {
  final NovaOrbState state;
  final double size;
  final bool showLabel;
  final String? label;
  final String? subtitle;

  const NovaCoreOrb({
    super.key,
    required this.state,
    this.size = 220,
    this.showLabel = true,
    this.label,
    this.subtitle,
  });

  @override
  State<NovaCoreOrb> createState() => _NovaCoreOrbState();
}

class _NovaCoreOrbState extends State<NovaCoreOrb>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;

  late final Animation<double> _breathScale;
  late final Animation<double> _pulseScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _breathScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );

    _ringOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant NovaCoreOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncAnimations();
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  void _syncAnimations() {
    switch (widget.state) {
      case NovaOrbState.idle:
        _breathController.repeat(reverse: true);
        _pulseController.stop();
        _pulseController.value = 0.0;
        _ringController.repeat(reverse: true);
        break;
      case NovaOrbState.listening:
        _breathController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
        _ringController.repeat();
        break;
      case NovaOrbState.speaking:
        _breathController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
        _ringController.repeat();
        break;
      case NovaOrbState.sleeping:
        _breathController.duration = const Duration(milliseconds: 3600);
        _breathController.repeat(reverse: true);
        _pulseController.stop();
        _pulseController.value = 0.0;
        _ringController.repeat(reverse: true);
        break;
      case NovaOrbState.fullyOff:
        _breathController.stop();
        _pulseController.stop();
        _ringController.stop();
        _breathController.value = 0.0;
        _pulseController.value = 0.0;
        _ringController.value = 0.0;
        break;
    }

    if (widget.state != NovaOrbState.sleeping) {
      _breathController.duration = const Duration(milliseconds: 2800);
    }
  }

  Color _coreColor() {
    switch (widget.state) {
      case NovaOrbState.idle:
        return const Color(0xFFB7302F);
      case NovaOrbState.listening:
        return const Color(0xFFED2C2E);
      case NovaOrbState.speaking:
        return const Color(0xFFFF3B3F);
      case NovaOrbState.sleeping:
        return const Color(0xFF5E0A0C);
      case NovaOrbState.fullyOff:
        return const Color(0xFF4A3732);
    }
  }

  String _defaultLabel() {
    switch (widget.state) {
      case NovaOrbState.idle:
        return 'Hazır';
      case NovaOrbState.listening:
        return 'Dinliyor';
      case NovaOrbState.speaking:
        return 'Konuşuyor';
      case NovaOrbState.sleeping:
        return 'Beklemede';
      case NovaOrbState.fullyOff:
        return 'Kapalı';
    }
  }

  String _defaultSubtitle() {
    switch (widget.state) {
      case NovaOrbState.idle:
        return 'Asistan çekirdeği aktif';
      case NovaOrbState.listening:
        return 'Sesinizi algılıyor';
      case NovaOrbState.speaking:
        return 'Yanıt hazırlanıyor';
      case NovaOrbState.sleeping:
        return 'Sakin dinleme halinde';
      case NovaOrbState.fullyOff:
        return 'Enerji çekirdeği pasif';
    }
  }

  double _statePulseMultiplier() {
    switch (widget.state) {
      case NovaOrbState.idle:
        return 0.02;
      case NovaOrbState.listening:
        return 0.05;
      case NovaOrbState.speaking:
        return 0.08;
      case NovaOrbState.sleeping:
        return 0.01;
      case NovaOrbState.fullyOff:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color coreColor = _coreColor();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _pulseController,
        _ringController,
      ]),
      builder: (context, _) {
        final double breath = _breathScale.value;
        final double pulse =
            1.0 + (_pulseController.value * _statePulseMultiplier());
        final double totalScale = widget.state == NovaOrbState.fullyOff
            ? 0.96
            : breath * pulse;

        final double ringWave = 0.90 + (_ringController.value * 0.32);
        final double ringAlpha = widget.state == NovaOrbState.fullyOff
            ? 0.0
            : (0.10 + (_ringOpacity.value * 0.14));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: Transform.scale(
                  scale: totalScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: ringWave,
                        child: Container(
                          width: widget.size * 0.88,
                          height: widget.size * 0.88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: coreColor.withOpacity(ringAlpha),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: coreColor.withOpacity(0.14),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: widget.size * 0.72,
                        height: widget.size * 0.72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.28),
                              coreColor.withOpacity(0.82),
                              const Color(0xFF5E0A0C).withOpacity(0.94),
                            ],
                            stops: const [0.0, 0.42, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: coreColor.withOpacity(0.38),
                              blurRadius: 34,
                              spreadRadius: 7,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.08),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: CustomPaint(
                              painter: _NovaOrbGlassPainter(
                                state: widget.state,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: widget.size * 0.42,
                        height: widget.size * 0.42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.22),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.28, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 22),
              Text(
                widget.label ?? _defaultLabel(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle ?? _defaultSubtitle(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _NovaOrbGlassPainter extends CustomPainter {
  final NovaOrbState state;

  const _NovaOrbGlassPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final Paint topGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.28),
          Colors.white.withOpacity(0.06),
          Colors.transparent,
        ],
      ).createShader(rect);

    final Paint lowerShade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.06),
          Colors.black.withOpacity(0.18),
        ],
      ).createShader(rect);

    final Path upperGlass = Path()
      ..addOval(
        Rect.fromLTWH(
          size.width * 0.18,
          size.height * 0.12,
          size.width * 0.48,
          size.height * 0.24,
        ),
      );

    final Path sideGlass = Path()
      ..moveTo(size.width * 0.22, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.06,
        size.width * 0.78,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.18,
        size.width * 0.28,
        size.height * 0.34,
      )
      ..close();

    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), lowerShade);
    canvas.drawPath(sideGlass, topGlow);
    canvas.drawPath(upperGlass, topGlow);

    if (state == NovaOrbState.speaking || state == NovaOrbState.listening) {
      final Paint energyPaint = Paint()
        ..color = Colors.white.withOpacity(
          state == NovaOrbState.speaking ? 0.10 : 0.06,
        );

      final double waveRadius = size.width * 0.18;
      final Offset center = Offset(size.width * 0.54, size.height * 0.54);

      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(
          center.translate(math.sin(i * 1.2) * 6, math.cos(i * 1.6) * 6),
          waveRadius - (i * 8),
          energyPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NovaOrbGlassPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class NovaOrbReadabilityProfile {
  final double titleOpacity;
  final double subtitleOpacity;
  final double glowOpacity;
  final double ringOpacity;
  final String emotionHint;

  const NovaOrbReadabilityProfile({
    required this.titleOpacity,
    required this.subtitleOpacity,
    required this.glowOpacity,
    required this.ringOpacity,
    required this.emotionHint,
  });
}

extension NovaCoreOrbReadabilityExtension on NovaCoreOrb {
  NovaOrbReadabilityProfile buildReadabilityProfile() {
    switch (state) {
      case NovaOrbState.speaking:
        return const NovaOrbReadabilityProfile(
          titleOpacity: 1.0,
          subtitleOpacity: 0.90,
          glowOpacity: 0.24,
          ringOpacity: 0.32,
          emotionHint: 'aktif, canlı, güven veren',
        );
      case NovaOrbState.listening:
        return const NovaOrbReadabilityProfile(
          titleOpacity: 0.98,
          subtitleOpacity: 0.84,
          glowOpacity: 0.18,
          ringOpacity: 0.24,
          emotionHint: 'dikkatli ve hazır',
        );
      case NovaOrbState.sleeping:
        return const NovaOrbReadabilityProfile(
          titleOpacity: 0.94,
          subtitleOpacity: 0.78,
          glowOpacity: 0.12,
          ringOpacity: 0.16,
          emotionHint: 'sakin ve beklemede',
        );
      case NovaOrbState.fullyOff:
        return const NovaOrbReadabilityProfile(
          titleOpacity: 0.86,
          subtitleOpacity: 0.64,
          glowOpacity: 0.04,
          ringOpacity: 0.08,
          emotionHint: 'tam uyku',
        );
      case NovaOrbState.idle:
        return const NovaOrbReadabilityProfile(
          titleOpacity: 0.96,
          subtitleOpacity: 0.80,
          glowOpacity: 0.14,
          ringOpacity: 0.18,
          emotionHint: 'dengede',
        );
    }
  }

  String buildOverlayAccessibilityMemo() {
    final profile = buildReadabilityProfile();
    return <String>[
      'ORB GÖRSEL ERİŞİLEBİLİRLİK NOTU:',
      '- başlık opaklığı: ${profile.titleOpacity.toStringAsFixed(2)}',
      '- alt başlık opaklığı: ${profile.subtitleOpacity.toStringAsFixed(2)}',
      '- glow opaklığı: ${profile.glowOpacity.toStringAsFixed(2)}',
      '- ring opaklığı: ${profile.ringOpacity.toStringAsFixed(2)}',
      '- duygu ipucu: ${profile.emotionHint}',
      'Kural: yazı kontrastı şeffaflığı bozmayacak kadar yüksek, alttaki ekrana engel olmayacak kadar ölçülü tutulur.',
    ].join('\n');
  }
}
