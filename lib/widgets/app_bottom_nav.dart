import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
  });

  static const double baseHeight = 74;

  static double heightFor(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return baseHeight + bottom;
  }

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;

    String route = '/home';

    if (index == 0) route = '/home';
    if (index == 1) route = '/scan';
    if (index == 2) route = '/collection';
    if (index == 3) route = '/missions';

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    final safeBottom = bottom == 0 ? 4.0 : (bottom * 0.58).clamp(10.0, 20.0).toDouble();

    return Container(
      width: double.infinity,
      height: heightFor(context),
      padding: EdgeInsets.only(top: 4, bottom: safeBottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context: context,
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          _navItem(
            context: context,
            index: 1,
            icon: Icons.center_focus_weak_rounded,
            label: 'Scan',
          ),
          _navItem(
            context: context,
            index: 2,
            icon: Icons.layers_rounded,
            label: 'Collection',
          ),
          _navItem(
            context: context,
            index: 3,
            icon: Icons.format_list_bulleted_rounded,
            label: 'Mission',
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool active = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _navigate(context, index),
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: active ? 32 : 29,
                color: active ? Colors.black : const Color(0xFF9A9A9A),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.2,
                  height: 1,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                  color: active ? Colors.black : const Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
