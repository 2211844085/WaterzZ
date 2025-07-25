import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SettingsPage extends StatefulWidget {
  final int currentGoal;
  final Function(int) onGoalChange;

  const SettingsPage({
    super.key,
    required this.currentGoal,
    required this.onGoalChange,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int selectedGoal;
  final customController = TextEditingController();

  // -- متغيرات الإشعارات --
  bool _notificationsEnabled = false;
  Timer? _timer;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    selectedGoal = widget.currentGoal;
    customController.text = selectedGoal.toString();
    _initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // دالة رئيسية لتهيئة كل شيء يتعلق بالإشعارات
  Future<void> _initialize() async {
    await _loadPreferences();
    await _requestPermission();
    await _initNotifications();

    if (_notificationsEnabled) {
      _startReminders();
    }
  }

  // -- دوال الإشعارات --

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  Future<void> _requestPermission() async {
    await Permission.notification.request();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(settings);
    tz.initializeTimeZones();
  }

  Future<void> _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel_5sec',
      'Water Reminders (5s)',
      channelDescription: 'Reminder to drink water every 5 seconds.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '💧 اشرب ماء!',
      'مرت 5 ثوانٍ، حان وقت شرب الماء.',
      notificationDetails,
    );
  }

  void _startReminders() {
    _timer?.cancel();
    if (_notificationsEnabled) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _showNotification();
      });
    }
  }

  void _stopReminders() {
    _timer?.cancel();
  }

  // -- دوال صفحة الإعدادات --
  void updateGoal(int value) {
    setState(() {
      selectedGoal = value;
      customController.text = value.toString();
    });
    widget.onGoalChange(value);
  }

  void saveCustomGoal() {
    int custom = int.tryParse(customController.text) ?? widget.currentGoal;
    if (custom > 0) {
      updateGoal(custom);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تحديث الهدف إلى $custom مل"),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

  // ✅ تم إرجاع هذه الدالة إلى مكانها الصحيح
  Widget _quickGoalButton(String label, int value) {
    return GestureDetector(
      onTap: () => updateGoal(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: selectedGoal == value ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: selectedGoal == value ? Colors.white : Colors.black)),
            Text("$value ml",
                style: TextStyle(
                    fontSize: 12,
                    color:
                    selectedGoal == value ? Colors.white70 : Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  // بطاقة التذكيرات
  Widget reminderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.blue),
              SizedBox(width: 8),
              Text("Reminders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Enable Reminders (Every 5 Sec)", style: TextStyle(fontSize: 16)),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _savePreferences();

              if (_notificationsEnabled) {
                _startReminders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reminders enabled every 5 seconds.")),
                );
              } else {
                _stopReminders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reminders disabled.")),
                );
              }
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FD),
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ تم إرجاع كل الويدجتس الخاصة بالهدف إلى مكانها الصحيح
            const Text("Current Daily Goal", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop, size: 32, color: Colors.blue),
                    const SizedBox(height: 10),
                    Text("$selectedGoal ml",
                        style: const TextStyle(
                            fontSize: 24,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)),
                    const Text("per day", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Quick Set Goals", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickGoalButton("1.5L", 1500),
                _quickGoalButton("2L", 2000),
                _quickGoalButton("2.5L", 2500),
                _quickGoalButton("3L", 3000),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Custom Goal", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: customController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: "ml",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: "Enter your goal",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: saveCustomGoal,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Save Goal"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            reminderCard(),
          ],
        ),
      ),
    );
  }
}