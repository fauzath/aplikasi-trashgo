import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/trash_dataset.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_back_button.dart';
import 'splash_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  String selectedTab = 'Anorganik';
  String? selectedItemId;
  bool _missionOpenMarked = false;

  void changeTab(String tab) {
    setState(() {
      selectedTab = tab;
      selectedItemId = null;
    });
  }

  void selectItem(String itemId) {
    setState(() {
      selectedItemId = itemId;
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }


  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _markCollectionMissionOpened(String uid) async {
    final todayKey = _dateKey(DateTime.now());
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.update({
      'missionProgress.$todayKey.mission_collection': true,
      'lastCollectionOpenDate': todayKey,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_missionOpenMarked) {
      _missionOpenMarked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markCollectionMissionOpened(user.uid).catchError((_) {});
      });
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> unlockedItems = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          unlockedItems = _asMap(data['unlockedItems']);
        }

        final List<TrashItem> tabItems = TrashDataset.byCategory(selectedTab);

        final List<TrashItem> unlockedTabItems = tabItems
            .where((item) => unlockedItems[item.id] == true)
            .toList();

        TrashItem? previewItem;

        if (selectedItemId != null) {
          for (final item in tabItems) {
            final bool itemUnlocked = unlockedItems[item.id] == true;

            if (item.id == selectedItemId && itemUnlocked) {
              previewItem = item;
              break;
            }
          }
        }

        previewItem ??=
        unlockedTabItems.isNotEmpty ? unlockedTabItems.first : null;

        return Scaffold(
          body: AuthBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 19),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: const [
                        AppBackButton(),
                        SizedBox(width: 30),
                        Expanded(
                          child: Text(
                            'Collection',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  _previewCard(
                    context: context,
                    previewItem: previewItem,
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: _bottomPanel(
                      tabItems: tabItems,
                      unlockedItems: unlockedItems,
                    ),
                  ),

                  const AppBottomNav(selectedIndex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _previewCard({
    required BuildContext context,
    required TrashItem? previewItem,
  }) {
    final bool isUnlocked = previewItem != null;

    return Container(
      width: MediaQuery.of(context).size.width * 0.86,
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFF81A98C).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 25,
            left: 25,
            right: 25,
            child: SizedBox(
              height: 190,
              child: isUnlocked
                  ? Image.asset(
                previewItem.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    '?',
                    style: TextStyle(
                      fontSize: 150,
                      height: 0.9,
                      color: Color(0xFF41664F),
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              )
                  : const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 190,
                    height: 0.9,
                    color: Color(0xFF41664F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 105,
            child: Text(
              isUnlocked ? previewItem.name : 'Locked Item',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 72,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selectedTab == 'Organik'
                      ? const Color(0xFF7EA348)
                      : const Color(0xFF06C4D4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isUnlocked ? previewItem.category : selectedTab,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: Text(
              isUnlocked
                  ? previewItem.description
                  : 'Scan sampah kategori $selectedTab untuk membuka item baru.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel({
    required List<TrashItem> tabItems,
    required Map<String, dynamic> unlockedItems,
  }) {
    final int unlockedCount = tabItems
        .where((item) => unlockedItems[item.id] == true)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(39, 0, 39, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(13),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          _tabs(),

          const SizedBox(height: 8),

          Transform.translate(
            offset: const Offset(0, -2),
            child: Text(
              '$unlockedCount / ${tabItems.length} unlocked',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
            ),
          ),

          Expanded(
            child: _grid(
              tabItems: tabItems,
              unlockedItems: unlockedItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => changeTab('Anorganik'),
                child: Text(
                  'Anorganik',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTab == 'Anorganik'
                        ? Colors.black
                        : Colors.grey,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            Expanded(
              child: GestureDetector(
                onTap: () => changeTab('Organik'),
                child: Text(
                  'Organik',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedTab == 'Organik'
                        ? Colors.black
                        : Colors.grey,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Container(
                height: 1.5,
                color: selectedTab == 'Anorganik'
                    ? Colors.black
                    : Colors.grey.shade300,
              ),
            ),

            Expanded(
              child: Container(
                height: 1.5,
                color: selectedTab == 'Organik'
                    ? Colors.black
                    : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _grid({
    required List<TrashItem> tabItems,
    required Map<String, dynamic> unlockedItems,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 14, bottom: 14),
      itemCount: tabItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 11,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final TrashItem? item =
        index < tabItems.length ? tabItems[index] : null;

        final bool isUnlocked =
        item == null ? false : unlockedItems[item.id] == true;

        final bool isSelected =
        item == null ? false : selectedItemId == item.id && isUnlocked;

        return GestureDetector(
          onTap: item != null && isUnlocked
              ? () {
            selectItem(item.id);
          }
              : null,
          child: CollectionBox(
            item: item,
            isUnlocked: isUnlocked,
            isSelected: isSelected,
          ),
        );
      },
    );
  }
}

class CollectionBox extends StatelessWidget {
  final TrashItem? item;
  final bool isUnlocked;
  final bool isSelected;

  const CollectionBox({
    super.key,
    required this.item,
    required this.isUnlocked,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final TrashItem? currentItem = item;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE880),
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
          color: const Color(0xFF41664F),
          width: 3,
        )
            : null,
      ),
      child: Center(
        child: isUnlocked && currentItem != null
            ? Image.asset(
          currentItem.imagePath,
          width: 55,
          height: 55,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              '?',
              style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7F7438)
              ),
            );
          },
        )
            : const Text(
          '?',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7F7438),
          ),
        ),
      ),
    );
  }
}

class HandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.15,
        size.width * 0.8,
        size.height,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}