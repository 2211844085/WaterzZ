import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SettingsPage extends StatefulWidget {
  final int currentGoal;
  final Function(int) onGoalChange;

  const SettingsPage({super.key, required this.currentGoal, required this.onGoalChange});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int selectedGoal;
  final customController = TextEditingController();
  bool _notificationsEnabled = false;
  int _reminderInterval = 2;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    selectedGoal = widget.currentGoal;
    customController.text = selectedGoal.toString();
    _initNotifications();
  }

  // الخطوة 1: تهيئة الإشعارات وطلب الصلاحية (مهم جداً)
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // طلب صلاحية الإشعارات من المستخدم (لأندرويد 13+)
    final androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    tz.initializeTimeZones();
  }

  // الخطوة 2: إصلاح دالة جدولة الإشعارات بالكامل
  Future<void> scheduleReminderNotifications() async {
    // أولاً، إلغاء كل الإشعارات القديمة
    await flutterLocalNotificationsPlugin.cancelAll();

    // لا تقم بالجدولة إذا كانت الميزة معطلة
    if (!_notificationsEnabled) {
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // جدولة 10 إشعارات قادمة (لضمان تغطية اليوم)
    for (int i = 1; i <= 10; i++) {
      final scheduledDate = now.add(Duration(hours: _reminderInterval * i));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        i, // معرّف فريد لكل إشعار
        // هنا قمنا بإضافة الفاصل الزمني لعنوان الإشعار
        '💧 Your $_reminderInterval-hour reminder!',
        'Stay hydrated. Tap to log your intake.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel_id',
            'Water Reminders',
            channelDescription: 'Reminders to drink water regularly',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        // لقد قمنا بإزالة السطر الخاطئ `matchDateTimeComponents`
      );
    }
  }

  // الخطوة 3: تعديل إشعار الاختبار أيضاً
  Future<void> showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      99, // معرّف مختلف للاختبار
      // هنا أيضاً قمنا بإضافة الفاصل الزمني لعنوان الإشعار
      '🔔  $_reminderInterval-hour reminder',
      'This is how your water reminder will look.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_test_channel_id',
          'Test Notifications',
          channelDescription: ' water notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ notification sent'),
          backgroundColor: Colors.green,
        ),
      );
    }
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

  Widget quickGoalButton(String label, int value) {
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
                    color:
                    selectedGoal == value ? Colors.white : Colors.black)),
            Text("$value ml",
                style: TextStyle(
                    fontSize: 12,
                    color: selectedGoal == value
                        ? Colors.white
                        : Colors.grey[700])),
          ],
        ),
      ),
    );
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
            title:
            const Text("Enable Notifications", style: TextStyle(fontSize: 16)),
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() {
                _notificationsEnabled = val;
              });
              // استدعاء الدالة الصحيحة عند التغيير
              await scheduleReminderNotifications();
            },
            activeColor: Colors.blue,
          ),
          if (_notificationsEnabled) ...[
            const SizedBox(height: 10),
            Text("Reminder Interval",
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _reminderInterval,
                  items: [1, 2, 3, 4].map((int hours) {
                    return DropdownMenuItem<int>(
                      value: hours,
                      child: Text(
                        "Every $hours hour${hours > 1 ? 's' : ''}",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? newVal) async {
                    if (newVal != null) {
                      setState(() {
                        _reminderInterval = newVal;
                      });
                      // استدعاء الدالة الصحيحة عند التغيير
                      await scheduleReminderNotifications();
                    }
                  },
                ),
              ),
            ),
          ]
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                quickGoalButton("1.5L", 1500),
                quickGoalButton("2L", 2000),
                quickGoalButton("2.5L", 2500),
                quickGoalButton("3L", 3000),
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
                border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            reminderCard(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: showTestNotification,
              icon: const Icon(Icons.notifications),
              label: const Text(" Notification"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade900,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}