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

class OffsiteStudentsPage extends StatefulWidget {
  const OffsiteStudentsPage({super.key});

  @override
  State<OffsiteStudentsPage> createState() => _OffsiteStudentsPageState();
}

class _OffsiteStudentsPageState extends State<OffsiteStudentsPage> {

  String? _selectedSite;

  // 🔹 Sample Data (now includes site field)
  final List<Map<String, String>> students = const [
    {
      "name": "Emily Johnson",
      "reason": "Medical Appointment",
      "time": "9:00 AM - 11:00 AM",
      "site": "Elemore Hall"
    },
    {
      "name": "Liam Carter",
      "reason": "School Trip",
      "time": "All Day",
      "site": "Windlestone"
    },
    {
      "name": "Sophia Martinez",
      "reason": "Family Emergency",
      "time": "10:30 AM - 12:00 PM",
      "site": "PACC"
    },
    {
      "name": "Noah Williams",
      "reason": "Sports Event",
      "time": "1:00 PM - 3:00 PM",
      "site": "Elemore Hall"
    },
  ];

  @override
  Widget build(BuildContext context) {

    // Filter by selected site
    final filteredStudents = _selectedSite == null
        ? students
        : students.where((s) => s["site"] == _selectedSite).toList();

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
        child: Column(
          children: [

            // 🔹 DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey[200]!, width: 1.2),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedSite,
                hint: Text(
                  'Filter by Site',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[600],
                  ),
                ),
                underline: const SizedBox(),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'Elemore Hall',
                    child: Text('Elemore Hall'),
                  ),
                  DropdownMenuItem(
                    value: 'Windlestone',
                    child: Text('Windlestone'),
                  ),
                  DropdownMenuItem(
                    value: 'PACC',
                    child: Text('PACC'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSite = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 STUDENT LIST
            Expanded(
              child: ListView.separated(
                itemCount: filteredStudents.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];

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
                              const SizedBox(height: 4),
                              Text(
                                student["time"]!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
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
          ],
        ),
      ),
    );
  }
}