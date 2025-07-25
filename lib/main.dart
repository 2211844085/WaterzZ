import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'HomePage.dart';
import 'LogPage.dart';
import 'SettingsPage.dart';

void main() => runApp(WaterzzApp());

class WaterzzApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WateRzZ',
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class WaterEntry {
  final int amount;
  final DateTime time;

  WaterEntry(this.amount, this.time);
}

class DailyWater {
  final DateTime date;
  List<WaterEntry> entries;

  DailyWater({required this.date, required this.entries});
}

class _MainScreenState extends State<MainScreen> {
  int currentWater = 0;
  int goal = 2000;
  List<DailyWater> dailyLogs = [];

  int selectedIndex = 0;

  // للتحديث التلقائي حسب اليوم
  void _checkDateReset() {
    DateTime now = DateTime.now();
    if (dailyLogs.isEmpty) {
      dailyLogs.add(DailyWater(date: now, entries: []));
      currentWater = 0;
    } else {
      DateTime lastDate = dailyLogs.first.date;
      if (!_isSameDay(lastDate, now)) {
        dailyLogs.insert(0, DailyWater(date: now, entries: []));
        currentWater = 0;
      } else {
        currentWater = dailyLogs.first.entries.fold(0, (sum, e) => sum + e.amount);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void addWater(int amount) {
    setState(() {
      _checkDateReset();

      dailyLogs.first.entries.insert(0, WaterEntry(amount, DateTime.now()));

      currentWater += amount;

      // لو شربت أكثر من الهدف، نخلي العرض 100% في الصفحة الرئيسية
      if (currentWater > goal) currentWater = currentWater; // نحتفظ بالقيمة كما هي

      // حافظ فقط على آخر 30 يوم
      if (dailyLogs.length > 30) {
        dailyLogs.removeLast();
      }
    });
  }

  void deleteEntry(int dailyIndex, int entryIndex) {
    setState(() {
      DateTime now = DateTime.now();
      // ما تسمح بحذف من أيام قديمة، فقط اليوم الحالي
      if (_isSameDay(dailyLogs[dailyIndex].date, now)) {
        int amountToRemove = dailyLogs[dailyIndex].entries[entryIndex].amount;
        dailyLogs[dailyIndex].entries.removeAt(entryIndex);

        // تحديث الكمية الحالية بعد الحذف
        currentWater -= amountToRemove;
        if (currentWater < goal) {
          // لا نخفض عن 0
          if (currentWater < 0) currentWater = 0;
        } else if (currentWater >= goal) {
          // لو فوق الهدف خلي العرض 100%
          currentWater = currentWater;
        }
      }
    });
  }

  void clearAll() {
    setState(() {
      DateTime now = DateTime.now();
      // نحتفظ بسجل اليوم فقط ونمسح ما عدا اليوم
      dailyLogs = dailyLogs.where((day) => _isSameDay(day.date, now)).toList();
      if (dailyLogs.isEmpty) {
        dailyLogs.add(DailyWater(date: now, entries: []));
      }
      currentWater = 0;
      dailyLogs.first.entries.clear();
    });
  }

  void onGoalChange(int newGoal) {
    setState(() {
      goal = newGoal;
      // في حال الهدف تغير وجب تحديث currentWater إذا لزم الأمر
      _checkDateReset();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkDateReset();
  }

  List<Widget> get pages => [
    HomePage(
      currentWater: currentWater,
      goal: goal,
      onAdd: addWater,
      onGoalChange: onGoalChange,
    ),
    LogPage(
      dailyLogs: dailyLogs,
      onDeleteEntry: deleteEntry,
      onClearAll: clearAll,
    ),
    SettingsPage(
      currentGoal: goal,
      onGoalChange: onGoalChange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) => setState(() => selectedIndex = value),
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Log"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class CircleProgressPainter extends CustomPainter {
  final double progress;

  CircleProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: 3.14 * 2,
        colors: [Colors.blue, Colors.blue],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);
    double sweepAngle = 3.14 * 2 * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14 / 2,
        sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
