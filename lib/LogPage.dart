import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class LogPage extends StatelessWidget {
  final List<DailyWater> dailyLogs;
  final Function(int dailyIndex, int entryIndex) onDeleteEntry;
  final VoidCallback onClearAll;
  final int goal; // هذا المتغير لم نعد نعتمد عليه للعرض

  const LogPage({
    required this.dailyLogs,
    required this.onDeleteEntry,
    required this.onClearAll,
    required this.goal,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
          if (dailyLogs.any((day) => day.entries.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: "Clear All",
              onPressed: () {
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
                          onClearAll();
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
      body: dailyLogs.isEmpty || dailyLogs.every((day) => day.entries.isEmpty)
          ? Center(
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
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: dailyLogs.length,
          itemBuilder: (context, dayIndex) {
            final day = dailyLogs[dayIndex];
            int dailyTotal = day.entries.fold(0, (sum, entry) => sum + entry.amount);

            // **هنا التعديل الأهم: نستخدم الهدف الخاص باليوم نفسه**
            int goalForThisDay = day.goalForThatDay;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                // جعل سجل اليوم مفتوحًا تلقائيًا
                initiallyExpanded: _isSameDay(day.date, DateTime.now()),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        // عرض كلمة "Today" لليوم الحالي
                        _isSameDay(day.date, DateTime.now())
                            ? "Today"
                            : DateFormat('EEEE, MMM d').format(day.date),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    // **تعديل هنا: المقارنة مع الهدف الخاص باليوم**
                    if (dailyTotal >= goalForThisDay)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                subtitle: Text(
                  // **تعديل هنا: عرض الهدف الخاص باليوم**
                  "$dailyTotal ml / $goalForThisDay ml",
                  style: TextStyle(color: dailyTotal >= goalForThisDay ? Colors.green : Colors.blue),
                ),
                children: day.entries.isEmpty
                    ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "No entries for this day.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                ]
                    : day.entries
                    .asMap()
                    .entries
                    .map(
                      (entry) => ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blue),
                    title: Text("${entry.value.amount} ml"),
                    subtitle: Text(DateFormat('hh:mm a').format(entry.value.time)),
                    trailing: _canDelete(day.date)
                        ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDeleteEntry(dayIndex, entry.key),
                    )
                        : null,
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

  bool _canDelete(DateTime date) {
    DateTime now = DateTime.now();
    return _isSameDay(date, now);
  }
}