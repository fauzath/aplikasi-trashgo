import 'dart:async';

import 'package:flutter/material.dart';

enum AppPopupType {
  success,
  warning,
  error,
  info,
}

class AppPopup {
  const AppPopup._();

  static void show(
    BuildContext context, {
    required String message,
    String title = 'Notification',
    AppPopupType type = AppPopupType.info,
    Duration duration = const Duration(milliseconds: 2300),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _PopupToast(
          title: title,
          message: message,
          type: type,
        );
      },
    );

    overlay.insert(entry);

    Timer(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _PopupToast extends StatefulWidget {
  final String title;
  final String message;
  final AppPopupType type;

  const _PopupToast({
    required this.title,
    required this.message,
    required this.type,
  });

  @override
  State<_PopupToast> createState() => _PopupToastState();
}

class _PopupToastState extends State<_PopupToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case AppPopupType.success:
        return const Color(0xFF20B65A);
      case AppPopupType.warning:
        return const Color(0xFFFFC400);
      case AppPopupType.error:
        return const Color(0xFFFF5A36);
      case AppPopupType.info:
        return const Color(0xFF06C4D4);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppPopupType.success:
        return Icons.check_circle_rounded;
      case AppPopupType.warning:
        return Icons.warning_amber_rounded;
      case AppPopupType.error:
        return Icons.error_rounded;
      case AppPopupType.info:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 14;

    return Positioned(
      top: top,
      left: 18,
      right: 18,
      child: IgnorePointer(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icon,
                        color: _accentColor,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
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
