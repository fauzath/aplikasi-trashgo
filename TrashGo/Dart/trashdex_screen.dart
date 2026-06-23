import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_data_provider.dart';
import '../models/trash_item.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/app_bottom_nav.dart';

class TrashdexScreen extends StatefulWidget {
  const TrashdexScreen({super.key});

  @override
  State<TrashdexScreen> createState() => _TrashdexScreenState();
}

class _TrashdexScreenState extends State<TrashdexScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  TrashItem? _selected;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _selected = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gd = context.watch<GameDataProvider>();
    final isAnorganik = _tabCtrl.index == 0;
    final items = isAnorganik ? gd.anorganikItems : gd.organikItems;

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Featured preview panel
              _FeaturedPanel(item: _selected),
              // Drag handle
              Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
              // Bottom sheet style grid
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabCtrl,
                        labelStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400),
                        labelColor: AppColors.textDark,
                        unselectedLabelColor: AppColors.textLight,
                        indicatorColor: AppColors.textDark,
                        tabs: const [Tab(text: 'Anorganik'), Tab(text: 'Organik')],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _ItemGrid(items: gd.anorganikItems, selected: _selected, onSelect: (i) => setState(() => _selected = i)),
                            _ItemGrid(items: gd.organikItems, selected: _selected, onSelect: (i) => setState(() => _selected = i)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          if (i == 1) Navigator.pushReplacementNamed(context, AppRoutes.scan);
          if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.profile);
        },
      ),
    );
  }
}

class _FeaturedPanel extends StatelessWidget {
  final TrashItem? item;
  const _FeaturedPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: item == null
          ? Center(child: Text('?', style: GoogleFonts.poppins(fontSize: 120, fontWeight: FontWeight.w900, color: AppColors.primaryGreen.withOpacity(0.4))))
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gradientCyan.withOpacity(0.7), AppColors.gradientYellow.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(item!.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(item!.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  final List<TrashItem> items;
  final TrashItem? selected;
  final Function(TrashItem) onSelect;

  const _ItemGrid({required this.items, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, childAspectRatio: 1, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = selected?.id == item.id;
        return _ItemCard(item: item, isSelected: isSelected, onTap: () {
          if (item.isUnlocked) {
            onSelect(item);
            if (item.isUnlocked) _showDetail(context, item);
          }
        });
      },
    );
  }

  void _showDetail(BuildContext context, TrashItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final TrashItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.cardYellow,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: AppColors.primaryGreen, width: 2.5) : null,
        ),
        child: item.isUnlocked
            ? Center(child: Text(item.name.substring(0, 2), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)))
            : Center(child: Text('?', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryGreen.withOpacity(0.5)))),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final TrashItem item;
  const _DetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.category == TrashCategory.anorganik ? AppColors.accentBlue.withOpacity(0.15) : AppColors.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.category == TrashCategory.anorganik ? 'Anorganik' : 'Organik',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                color: item.category == TrashCategory.anorganik ? AppColors.accentBlue : AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          _Section(title: '📖 Description', content: item.description),
          const SizedBox(height: 12),
          _Section(title: '🌍 Eco Impact', content: item.ecoImpact),
          const SizedBox(height: 12),
          _Section(title: '♻️ Recycling Tips', content: item.recyclingTips),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 4),
      Text(content, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium)),
    ]);
  }
}
