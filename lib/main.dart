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

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class WaterEntry {
  final int amount;
  final DateTime time;

  WaterEntry(this.amount, this.time);
}

class _MainScreenState extends State<MainScreen> {
  int currentWater = 0;
  int goal = 2000;
  List<WaterEntry> log = [];

  int selectedIndex = 0;

  void addWater(int amount) {
    setState(() {
      currentWater += amount;
      if (currentWater > goal) currentWater = goal;
      log.insert(0, WaterEntry(amount, DateTime.now()));
    });
  }

  void deleteEntry(int index) {
    setState(() {
      currentWater -= log[index].amount;
      if (currentWater < 0) currentWater = 0;
      log.removeAt(index);
    });
  }

  List<Widget> get pages => [
    HomePage(
      currentWater: currentWater,
      goal: goal,
      onAdd: addWater,

      onGoalChange: (newGoal) => setState(() => goal = newGoal),
    ),

    LogPage(
      log: log,
      onDelete: deleteEntry,
      onClearAll: () {
        setState(() {
          log.clear();
          currentWater = 0;
        });
      },
    ),
    SettingsPage(
      currentGoal: goal,
      onGoalChange: (newGoal) => setState(() => goal = newGoal),
    ),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) => setState(() => selectedIndex = value),
        selectedItemColor: Colors.blue,              // ← لون الأيقونة/النص لما تكون محددة
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
        startAngle: 0.0,
        endAngle: 3.14 * 2,
        colors: [Colors.blue, Colors.blue],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);
    double sweepAngle = 3.14 * 2 * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -3.14 / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}