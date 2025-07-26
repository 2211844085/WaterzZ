import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart';

class HomePage extends StatelessWidget {
  final int currentWater;
  final int goal;
  final Function(int) onAdd;
  final Function(int) onGoalChange;

  //  (Constructor HomePage)
  const HomePage({
    required this.currentWater,
    required this.goal,
    required this.onAdd,
    required this.onGoalChange,
  });

//تعديل الهدف اليومي dialog
  void _showGoalDialog(BuildContext context) {
    //تحكم في حقل النص الخاص بالهدف
    final controller = TextEditingController(text: goal.toString());
// showDialog لعرض مربع الحوار
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Daily Goal"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter new goal in ml"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                onGoalChange(newGoal);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  //  دالة لإظهار dialog عند تحقيق الهدف اليومي الف مبروك

  void showGoalReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            '🎉 ألف مبروك!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
        content: Text(
          'لقد حققت هدفك اليومي من شرب الماء يا بطل',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[800],
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'تم',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


// حساب النسبة المئوية لكمية الماء المشروبة بالنسبة للهدف
  @override
  Widget build(BuildContext context) {
    double percent = 0;
    if (currentWater >= goal) {
      percent = 1.0;
    } else {
      // clamp(0, 1) تضمن أن القيمة لن تكون أقل من 0 أو أكبر من 1
      percent = (currentWater / goal).clamp(0, 1);
    }
    return Scaffold(
      backgroundColor: Color(0xFFF2F7FD),
      appBar: AppBar(
        title: Text('WateRzZ'),
        centerTitle: true,
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,

        elevation: 0, // إزالة الظل تحت الـ AppBar
      ),

      // SingleChildScrollView يسمح للمستخدم بالتمرير إذا كانت المحتويات أطول من الشاشة
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Stay Hydrated", style: TextStyle(color: Colors.black)),
            SizedBox(height: 20),

            // بطاقة عرض التقدم اليومي
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16),
                child: Column(
                  children: [
                    Text("Today's Progress",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    // TweenAnimationBuilder يقوم بعمل حركة انتقال (animation) للـ progress bar
                    // بدلاً من ظهوره فجأة، يمتلئ بشكل تدريجي
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: percent),// القيمة تبدأ من 0 وتنتهي عند النسبة الحالية
                      duration: Duration(milliseconds: 800),// مدة الحركة
                      builder: (context, value, _) => SizedBox(
                        height: 160,
                        width: 160,
                        // Stack لوضع الويدجتس فوق بعضها (الدائرة فوقها النص)
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // ويدجت مخصص لرسم الدائرة، يستقبل قيمة التقدم
                            CustomPaint(
                              size: Size(160, 160),
                              painter: CircleProgressPainter(value),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("${(value * 100).toInt()}%",
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text("$currentWater ml / $goal ml",
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // زر لتعديل الهدف
                    ElevatedButton.icon(
                      onPressed: () => _showGoalDialog(context),
                      icon: Icon(Icons.flag),
                      label: Text("Goal: $goal ml"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // قسم الإضافة السريعة
            Align(
                alignment: Alignment.centerLeft,
                child: Text("Quick Add", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            SizedBox(height: 10),
            // صف أفقي يحتوي على أزرار الإضافة السريعة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                quickAddButton(context, "250ml", Icons.local_cafe, 250),
                quickAddButton(context, "500ml", Icons.local_drink, 500),
                quickAddButton(context, "1000ml", Icons.water_drop, 1000),
              ],
            ),
            SizedBox(height: 20),
            // زر لإضافة كمية مخصصة
            ElevatedButton(
              onPressed: () => customAmountDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade900,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text("Custom Amount", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              '💧 "وجعلنا من الماء كل شيء حي"',
              style: TextStyle(fontSize: 20, fontStyle: FontStyle.normal, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإنشاء أزرار الإضافة السريعة
  Widget quickAddButton(BuildContext context, String label, IconData icon, int amount) {
    return ElevatedButton(
      onPressed: () {
        // استدعاء دالة onAdd لتحديث الحالة في الـ MainScreen
        onAdd(amount);

        //  التحقق إذا تم الوصول للهدف
        final newTotal = currentWater + amount;
        // الشرط: إذا كان المجموع السابق أقل من الهدف، والمجموع الجديد أصبح يساوي الهدف أو أكبر منه
        if (currentWater < goal && newTotal >= goal) {
          showGoalReachedDialog(context); // إظهار رسالة التهنئة
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        minimumSize: const Size(90, 90),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // دالة لإظهار مربع حوار لإضافة كمية مخصصة
  void customAmountDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Amount (ml)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "e.g. 300"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              int amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                onAdd(amount); // استدعاء الدالة لإضافة الكمية
                final newTotal = currentWater + amount;
                if (currentWater < goal && newTotal >= goal) {
                  showGoalReachedDialog(context); // إظهار رسالة التهنئة أيضاً هنا
                }
              }
              Navigator.pop(context); // إغلاق مربع الحوار
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

