// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _notificationsEnabled = false;
  int _reminderIntervalMinutes = 1;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    selectedGoal = widget.currentGoal;
    customController.text = selectedGoal.toString();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadPreferences();
    await _requestNotificationPermission();
    await _initNotifications();

    if (_notificationsEnabled) {
      _schedulePeriodicNotifications();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _reminderIntervalMinutes = prefs.getInt('interval_minutes') ?? 1;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('interval_minutes', _reminderIntervalMinutes);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(settings);
    tz.initializeTimeZones();
  }

  void _schedulePeriodicNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    final firstNotificationTime = now.add(Duration(minutes: _reminderIntervalMinutes));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '💧 Reminder!',
      'Time to drink water every $_reminderIntervalMinutes minute(s).',
      firstNotificationTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_channel_id',
          'Water Reminders',
          channelDescription: 'Reminders to drink water regularly',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      99,
      '🔔 Test Notification ($_reminderIntervalMinutes min)',
      'This is how your reminder will look.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_test_channel_id',
          'Test Notifications',
          channelDescription: 'Test reminder notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

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
          content: Text("Goal Updated to $custom ml"),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

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
            title: const Text("Enable Notifications", style: TextStyle(fontSize: 16)),
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() {
                _notificationsEnabled = val;
              });
              await _savePreferences();
              if (_notificationsEnabled) {
                _schedulePeriodicNotifications();
              } else {
                await flutterLocalNotificationsPlugin.cancelAll();
              }
            },
            activeColor: Colors.blue,
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 10),
            Text("Reminder Interval (in minutes)",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _reminderIntervalMinutes,
              items: [1, 2, 3, 5].map((int minutes) {
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Text("Every $minutes minute${minutes > 1 ? 's' : ''}"),
                );
              }).toList(),
              onChanged: (int? newVal) async {
                if (newVal != null) {
                  setState(() {
                    _reminderIntervalMinutes = newVal;
                  });
                  await _savePreferences();
                  _schedulePeriodicNotifications();
                }
              },
            ),
          ],
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: showTestNotification,
              icon: const Icon(Icons.notifications),
              label: const Text("Test Notification"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade900,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                    selectedGoal == value ? Colors.white : Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
