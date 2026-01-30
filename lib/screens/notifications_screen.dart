import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../services/storage_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.black),
            onPressed: () {
               // Mark all as read
               final box = Hive.box<AppNotification>(StorageService.notificationsBoxName);
               for (var msg in box.values) {
                 msg.isRead = true;
                 msg.save();
               }
            },
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<AppNotification>(StorageService.notificationsBoxName).listenable(),
        builder: (context, Box<AppNotification> box, _) {
          final notifications = box.values.toList()
             ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No notifications yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final note = notifications[index];
              return Dismissible(
                key: Key(note.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => note.delete(),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: note.isRead ? Colors.white : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Icon(
                          _getIconForType(note.type),
                          size: 20,
                          color: _getColorForType(note.type),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.body,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(note.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                      if (!note.isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    if (DateTime.now().difference(time).inDays < 1) {
       return DateFormat('h:mm a').format(time);
    } else {
       return DateFormat('MMM d').format(time);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'motivation': return Icons.wb_sunny_rounded;
      case 'alert': return Icons.warning_rounded;
      case 'reminder': return Icons.access_alarm_rounded;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
     switch (type) {
      case 'motivation': return Colors.orange;
      case 'alert': return Colors.red;
      case 'reminder': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
