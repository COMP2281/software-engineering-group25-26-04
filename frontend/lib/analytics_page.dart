import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OffsiteStudentsPage(),
    );
  }
}

/* -------------------- OFFSITE STUDENTS PAGE -------------------- */

class OffsiteStudentsPage extends StatelessWidget {
  const OffsiteStudentsPage({super.key});

  // 🔹 Sample Data (Replace with real data later)
  final List<Map<String, String>> students = const [
    {
      "name": "Emily Johnson",
      "reason": "Medical Appointment",
      "time": "9:00 AM - 11:00 AM"
    },
    {
      "name": "Liam Carter",
      "reason": "School Trip",
      "time": "All Day"
    },
    {
      "name": "Sophia Martinez",
      "reason": "Family Emergency",
      "time": "10:30 AM - 12:00 PM"
    },
    {
      "name": "Noah Williams",
      "reason": "Sports Event",
      "time": "1:00 PM - 3:00 PM"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text("Offsite Students"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: students.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final student = students[index];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student["name"]!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student["reason"]!,
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
