import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/app_back_button.dart';
import 'splash_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    try {
      final unreadNotifications =
      await notificationRef.where('isRead', isEqualTo: false).get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (!context.mounted) return;
      // Tidak menampilkan popup di halaman Notification.
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('Gagal update notifikasi: $e');
    }
  }

  Future<void> _clearNotifications(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    try {
      final notifications = await notificationRef.get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (!context.mounted) return;
      // Tidak menampilkan popup di halaman Notification.
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('Gagal hapus notifikasi: $e');
    }
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

    final notificationStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

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
                    SizedBox(width: 28),
                    Expanded(
                      child: Text(
                        'Notification',
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

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markAllAsRead(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006BA3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Mark Read',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _clearNotifications(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B2A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: notificationStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(25),
                          child: Text(
                            'Gagal memuat notifikasi:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada notifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }

                    final notifications = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 12);
                      },
                      itemBuilder: (context, index) {
                        final doc = notifications[index];
                        final data = doc.data();

                        final title =
                        (data['title'] ?? '[Nama notifikasi]').toString();

                        final description =
                        (data['description'] ?? '[keterangan notifikasi]')
                            .toString();

                        final bool isRead = data['isRead'] == true;

                        final Timestamp? createdAt =
                        data['createdAt'] is Timestamp
                            ? data['createdAt'] as Timestamp
                            : null;

                        return NotificationCard(
                          title: title,
                          description: description,
                          time: _formatTime(createdAt),
                          isRead: isRead,
                        );
                      },
                    );
                  },
                ),
              ),

              const AppBottomNav(selectedIndex: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 83,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFEDEDED) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: isRead
            ? null
            : Border.all(
          color: const Color(0xFFFFC400),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: isRead ? Colors.grey : const Color(0xFFFFC400),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}