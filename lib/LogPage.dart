import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart';

class LogPage extends StatelessWidget {
  final List<WaterEntry> log;
  final Function(int) onDelete;
  final VoidCallback onClearAll;

  const LogPage({
    required this.log,
    required this.onDelete,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    int total = log.fold(0, (sum, entry) => sum + entry.amount);
    return Scaffold(
      backgroundColor: Color(0xFFF2F7FD), // خلفية ناعمة مثل Home
      appBar: AppBar(
        title: Text("WateRzZ Log"),
        centerTitle: true,
        backgroundColor: Color(0xFF1976D2), // نفس لون AppBar Home
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (log.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: "Clear All",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Clear All Logs"),
                    content: Text("Are you sure you want to clear all water logs?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onClearAll();
                        },
                        child: Text("Clear All", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: log.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                Text("$total ml total", style: TextStyle(color: Colors.blue)),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: log.length,
                itemBuilder: (_, index) {
                  final entry = log[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.water_drop, color: Colors.blue),
                      title: Text("${entry.amount} ml"),
                      subtitle: Text(DateFormat('hh:mm a').format(entry.time)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onDelete(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}