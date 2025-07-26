import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class LogPage extends StatelessWidget {
  final List<DailyWater> dailyLogs; // قائمة تحتوي على سجلات كل الأيام
  final Function(int dailyIndex, int entryIndex) onDeleteEntry; // دالة لحذف إدخال معين
  final VoidCallback onClearAll;  // دالة لمسح كل السجلات
  final int goal;

  //constractur
  const LogPage({
    required this.dailyLogs,
    required this.onDeleteEntry,
    required this.onClearAll,
    required this.goal,
  });

// دالة للتحقق إذا كان تاريخان في نفس اليوم (نفس اليوم والشهر والسنة)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // دالة للتحقق إذا كان يمكن حذف إدخال معين (فقط إدخالات اليوم الحالي يمكن حذفها)
  bool _canDelete(DateTime date) {
    DateTime now = DateTime.now();
    return _isSameDay(date, now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FD),
      appBar: AppBar(
        title: const Text("WateRzZ Log"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // إظهار زر "مسح الكل" فقط إذا كانت هناك أي سجلات
          if (dailyLogs.any((day) => day.entries.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear All",
              onPressed: () {
                // إظهار مربع حوار للتأكيد قبل الحذف
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Clear All Logs"),
                    content: const Text("Are you sure you want to clear all water logs?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onClearAll();// استدعاء دالة مسح الكل من الـ MainScreen
                        },
                        child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      // جسم الصفحة: يعرض رسالة إذا كانت السجلات فارغة، أو يعرض القائمة إذا كانت تحتوي على بيانات
      body: dailyLogs.isEmpty || dailyLogs.every((day) => day.entries.isEmpty)
          ? Center(   // عرض رسالة في المنتصف في حالة عدم وجود سجلات
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.water_drop_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No water logged yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
            SizedBox(height: 5),
            Text("Start tracking your water intake from the Home tab", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
      // عرض قائمة السجلات
          : Padding(
        padding: const EdgeInsets.all(16.0),
        // ListView.builder هو الخيار الأفضل لعرض القوائم الطويلة لأنه يبني العناصر عند الحاجة فقط
        child: ListView.builder(
          itemCount: dailyLogs.length, // عدد الأيام في السجل
          itemBuilder: (context, dayIndex) {
            // الحصول على بيانات اليوم الحالي في التكرار
            final day = dailyLogs[dayIndex];
            // حساب المجموع اليومي باستخدام دالة fold
            int dailyTotal = day.entries.fold(0, (sum, entry) => sum + entry.amount);

            // **هنا التعديل الأهم: نستخدم الهدف الخاص باليوم نفسه**
            int goalForThisDay = day.goalForThatDay;

            // عرض بيانات كل يوم في بطاقة (Card)
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              // ExpansionTile هي ويدجت قابلة للفتح والإغلاق لعرض التفاصيل
              child: ExpansionTile(
                // جعل سجل اليوم مفتوحًا تلقائيًا
                initiallyExpanded: _isSameDay(day.date, DateTime.now()),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        // عرض كلمة "Today" لليوم الحالي، أو عرض التاريخ للأيام الأخرى
                        _isSameDay(day.date, DateTime.now())
                            ? "Today"
                            : DateFormat('EEEE, MMM d').format(day.date),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),

                    // إظهار علامة صح خضراء إذا تم تحقيق الهدف
                    if (dailyTotal >= goalForThisDay)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                // العنوان الفرعي الذي يظهر تحت العنوان الرئيسي
                subtitle: Text(
                  // **تعديل هنا: عرض الهدف الخاص باليوم**
                  "$dailyTotal ml / $goalForThisDay ml",
                  style: TextStyle(color: dailyTotal >= goalForThisDay ? Colors.green : Colors.blue),
                ),
                children: day.entries.isEmpty  // إذا لم تكن هناك إدخالات لهذا اليوم
                    ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "No entries for this day.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                ]
                    : day.entries // إذا كانت هناك إدخالات
                    .asMap()      // تحويل القائمة إلى خريطة للحصول على الـ index
                    .entries
                    .map(     // المرور على كل إدخال لإنشاء ListTile له
                      (entry) => ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blue),
                    title: Text("${entry.value.amount} ml"),  // كمية الماء
                    subtitle: Text(DateFormat('hh:mm a').format(entry.value.time)), // وقت الشرب
                        // عرض زر الحذف فقط إذا كان الإدخال من اليوم الحالي
                        trailing: _canDelete(day.date)
                        ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDeleteEntry(dayIndex, entry.key),
                    )
                        : null, // لا تعرض شيئاً إذا كان من يوم قديم
                  ),
                )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }

}