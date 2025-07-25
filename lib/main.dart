import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'time': time.toIso8601String(),
  };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    json['amount'],
    DateTime.parse(json['time']),
  );
}

class DailyWater {
  final DateTime date;
  List<WaterEntry> entries;
  final int goalForThatDay;

  DailyWater({
    required this.date,
    required this.entries,
    required this.goalForThatDay,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'goalForThatDay': goalForThatDay,
  };

  factory DailyWater.fromJson(Map<String, dynamic> json) => DailyWater(
    date: DateTime.parse(json['date']),
    entries: (json['entries'] as List)
        .map((e) => WaterEntry.fromJson(e))
        .toList(),
    goalForThatDay: json['goalForThatDay'] ?? 2000,
  );
}

class MainScreen extends StatefulWidget {
  // **✅ الحل: إضافة هذا الكونستركتر الثابت**
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentWater = 0;
  int goal = 2000;
  List<DailyWater> dailyLogs = [];
  int selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal', goal);
    String logsJson = jsonEncode(dailyLogs.map((item) => item.toJson()).toList());
    await prefs.setString('dailyLogs', logsJson);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      goal = prefs.getInt('goal') ?? 2000;
      String? logsJson = prefs.getString('dailyLogs');
      if (logsJson != null) {
        List<dynamic> decodedLogs = jsonDecode(logsJson);
        dailyLogs = decodedLogs.map((item) => DailyWater.fromJson(item)).toList();
      } else {
        dailyLogs = [];
      }
      _checkDateReset();
      isLoading = false;
    });
  }

  void _checkDateReset() {
    DateTime now = DateTime.now();
    if (dailyLogs.isEmpty) {
      dailyLogs.add(DailyWater(date: now, entries: [], goalForThatDay: goal));
      currentWater = 0;
    } else {
      DateTime lastDate = dailyLogs.first.date;
      if (!_isSameDay(lastDate, now)) {
        dailyLogs.insert(0, DailyWater(date: now, entries: [], goalForThatDay: goal));
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
      if (dailyLogs.length > 30) {
        dailyLogs.removeLast();
      }
    });
    _saveData();
  }

  void deleteEntry(int dailyIndex, int entryIndex) {
    setState(() {
      DateTime now = DateTime.now();
      if (_isSameDay(dailyLogs[dailyIndex].date, now)) {
        int amountToRemove = dailyLogs[dailyIndex].entries[entryIndex].amount;
        dailyLogs[dailyIndex].entries.removeAt(entryIndex);
        currentWater -= amountToRemove;
        if (currentWater < 0) currentWater = 0;
      }
    });
    _saveData();
  }

  void clearAll() {
    setState(() {
      DateTime now = DateTime.now();
      dailyLogs = dailyLogs.where((day) => _isSameDay(day.date, now)).toList();
      if (dailyLogs.isEmpty) {
        dailyLogs.add(DailyWater(date: now, entries: [], goalForThatDay: goal));
      }
      currentWater = 0;
      dailyLogs.first.entries.clear();
    });
    _saveData();
  }

  void onGoalChange(int newGoal) {
    setState(() {
      goal = newGoal;
      _checkDateReset();
      final todayLog = dailyLogs.first;
      dailyLogs[0] = DailyWater(
        date: todayLog.date,
        entries: todayLog.entries,
        goalForThatDay: newGoal,
      );
    });
    _saveData();
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
      goal: goal,
    ),
    SettingsPage(
      currentGoal: goal,
      onGoalChange: onGoalChange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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