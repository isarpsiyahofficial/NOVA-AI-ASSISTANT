// ignore_for_file: avoid_print, unnecessary_cast, prefer_initializing_formals, unused_local_variable, deprecated_member_use, prefer_final_fields, unused_element, prefer_interpolation_to_compose_strings, dead_code, unused_import, unused_field, curly_braces_in_flow_control_structures, unnecessary_import, prefer_spread_collections, unnecessary_this, prefer_collection_literals, duplicate_ignore, prefer_const_constructors, prefer_const_literals_to_create_immutables
// NOVA_ABSOLUTE_FINAL_CLEANUP_V1
import 'package:flutter/material.dart';

import '../../services/presence/nova_presence_service.dart';

class NovaPresenceIndicator extends StatefulWidget {
  final NovaPresenceService presenceService;

  const NovaPresenceIndicator({super.key, required this.presenceService});

  @override
  State<NovaPresenceIndicator> createState() => _NovaPresenceIndicatorState();
}

class _NovaPresenceIndicatorState extends State<NovaPresenceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.88,
      upperBound: 1.10,
    );

    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    widget.presenceService.addListener(_onPresenceChanged);
    _syncAnimation();
  }

  @override
  void dispose() {
    widget.presenceService.removeListener(_onPresenceChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onPresenceChanged() {
    if (!mounted) return;
    _syncAnimation();
    setState(() {});
  }

  void _syncAnimation() {
    if (widget.presenceService.isSpeaking &&
        widget.presenceService.isIndicatorVisible) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  Color _resolveColor(NovaPresenceState state) {
    switch (state) {
      case NovaPresenceState.idle:
        return const Color(0xFF8A6A62);
      case NovaPresenceState.listening:
        return const Color(0xFFED2C2E);
      case NovaPresenceState.speaking:
        return const Color(0xFFFF3B3F);
      case NovaPresenceState.sleeping:
        return Colors.indigo.shade300;
      case NovaPresenceState.fullyOff:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.presenceService.isIndicatorVisible) {
      return const SizedBox.shrink();
    }

    final size = widget.presenceService.settings.indicatorSize;
    final color = _resolveColor(widget.presenceService.state);

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: ScaleTransition(
              scale: _scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.90),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.30),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
