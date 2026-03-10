import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'logs_page.dart';
import 'log_modal.dart';
import 'analytics_page.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'config.dart';
import 'class_register_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Map<String, dynamic>>> _classesData;
  late Future<List<Map<String, dynamic>>> _incidentsData;
  late Future<List<Map<String, dynamic>>> _offsiteStudentsFuture;
  String? _selectedSite;
  String? _selectedOffsiteSite;
  Timer? _pollingTimer;

  final List<Map<String, dynamic>> _demoStudents = [
    {'student_id': 9001, 'name': 'Alex Carter'},
    {'student_id': 9002, 'name': 'Mia Johnson'},
    {'student_id': 9003, 'name': 'Noah Smith'},
    {'student_id': 9004, 'name': 'Sofia Ahmed'},
    {'student_id': 9005, 'name': 'Luca Brown'},
  ];

  final List<Color> _colors = [
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.blue,
    Colors.red,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _classesData = _fetchClasses(_selectedSite);
    _incidentsData = _fetchIncidents();
    _offsiteStudentsFuture = _fetchOffsiteStudents(_selectedOffsiteSite);
    _pollingTimer = Timer.periodic(const Duration(seconds: 600), (_) => _refreshData());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _classesData = _fetchClasses(_selectedSite);
      _incidentsData = _fetchIncidents(_selectedSite);
      _offsiteStudentsFuture = _fetchOffsiteStudents(_selectedOffsiteSite);
    });
  }

  int? _getSiteId(String? siteName) {
    switch (siteName) {
      case 'elemore_hall':
        return 1;
      case 'windlestone':
        return 2;
      case 'pacc':
        return 3;
      default:
        return null;
    }
  }

  String _getSiteLabel(int? siteId) {
    switch (siteId) {
      case 1:
        return 'Elemore Hall';
      case 2:
        return 'Windlestone';
      case 3:
        return 'PACC';
      default:
        return 'Unknown Site';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllClassesFromDb() async {
    final response = await ApiClient.get(
      '${AppConfig.apiUrl}/api/classes/',
      context: context,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load all classes');
    }

    final jsonData = jsonDecode(response.body) as List<dynamic>;
    return jsonData
        .map(
          (item) => {
            'class_id': item['class_id'],
            'class_name': (item['class_name'] ?? 'Unnamed Class').toString(),
            'staff_id': item['staff_id'],
            'site_combination_id': item['site_combination_id'],
          },
        )
        .toList();
  }

  Future<void> _showAllClassesPopup() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: _AllClassesFullscreenDialog(
          fetchClasses: _fetchAllClassesFromDb,
          getSiteLabel: _getSiteLabel,
          onClassTap: (selectedClass, navigationContext) async {
            final classData = {
              'class_id': selectedClass['class_id'],
              'name': (selectedClass['class_name'] ?? 'Unnamed Class')
                  .toString(),
              'is_demo': false,
            };
            await _openClassRegister(
              classData,
              navigationContext: navigationContext,
            );
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _buildDemoClass() {
    return {
      'class_id': -1,
      'name': 'Demo Class',
      'students': _demoStudents.length,
      'color': Colors.teal,
      'is_demo': true,
      'demo_students': _demoStudents,
      'site_combination_id': 1,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchStudentsForClass(int classId) async {
    try {
      final classStudentsResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/class-students/class/$classId/',
      );

      if (classStudentsResponse.statusCode != 200) {
        return [];
      }

      final classStudentsData =
          jsonDecode(classStudentsResponse.body) as List<dynamic>;
      if (classStudentsData.isEmpty) {
        return [];
      }

      final studentsResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/students/',
      );

      final Map<int, String> namesByStudentId = {};
      if (studentsResponse.statusCode == 200) {
        final studentsData = jsonDecode(studentsResponse.body) as List<dynamic>;
        for (final student in studentsData) {
          final studentId = student['student_id'];
          if (studentId is int) {
            final firstName = (student['first_name'] ?? '').toString();
            final lastName = (student['last_name'] ?? '').toString();
            final fullName = '$firstName $lastName'.trim();
            namesByStudentId[studentId] = fullName.isEmpty
                ? 'Student $studentId'
                : fullName;
          }
        }
      }

      return classStudentsData
          .map((entry) {
            final studentId = entry['student_id'];
            if (studentId is! int) return null;
            return {
              'student_id': studentId,
              'name': namesByStudentId[studentId] ?? 'Student $studentId',
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      log('Error fetching class students for register preview: $e');
      return [];
    }
  }

  Future<void> _openClassRegister(
    Map<String, dynamic> cls, {
    BuildContext? navigationContext,
  }) async {
    final isDemoClass = cls['is_demo'] == true;
    final targetContext = navigationContext ?? context;

    List<Map<String, dynamic>> students;
    if (isDemoClass) {
      students = (cls['demo_students'] as List<dynamic>)
          .map((student) => Map<String, dynamic>.from(student as Map))
          .toList();
    } else {
      final classId = cls['class_id'];
      students = classId is int ? await _fetchStudentsForClass(classId) : [];
    }

    if (!mounted) return;

    Navigator.push(
      targetContext,
      MaterialPageRoute(
        builder: (context) => ClassRegisterPage(
          className: cls['name'].toString(),
          classId: cls['class_id'] is int ? cls['class_id'] as int : null,
          isDemo: isDemoClass,
          students: students,
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClasses([String? siteFilter]) async {
    try {
      String url = '${AppConfig.apiUrl}/api/classes/';

      // If a site is selected, use the site-specific endpoint
      if (siteFilter != null) {
        int? siteId = _getSiteId(siteFilter);
        if (siteId != null) {
          url = '${AppConfig.apiUrl}/api/classes/site/$siteId/';
        }
      }

      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<Map<String, dynamic>> classes = [];

        for (int index = 0; index < jsonData.length; index++) {
          final item = jsonData[index];

          // Fetch student count for this class
          int studentCount = 0;
          try {
            final studentsResponse = await ApiClient.get(
              '${AppConfig.apiUrl}/api/class-students/class/${item['class_id']}/',
            );

            if (studentsResponse.statusCode == 200) {
              List<dynamic> studentsData = jsonDecode(studentsResponse.body);
              studentCount = studentsData.length;
            }
          } catch (e) {
            log(
              'Error fetching student count for class ${item['class_id']}: $e',
            );
          }

          classes.add({
            'class_id': item['class_id'],
            'name': item['class_name'],
            'students': studentCount,
            'color': _colors[index % _colors.length],
            'is_demo': false,
            'site_combination_id': item['site_combination_id'],
          });
        }

        classes.insert(0, _buildDemoClass());
        return classes;
      } else {
        throw Exception('Failed to load classes');
      }
    } catch (e) {
      log('Error fetching classes: $e');
      return [_buildDemoClass()];
    }
  }
  Future<List<Map<String, dynamic>>> _fetchOffsiteStudents(String? siteFilter) async {
   try {
    final attendanceResponse = await ApiClient.get('${AppConfig.apiUrl}/api/attendance/');
    final studentsResponse = await ApiClient.get('${AppConfig.apiUrl}/api/students/');
    final registersResponse = await ApiClient.get('${AppConfig.apiUrl}/api/registers/');

    if (attendanceResponse.statusCode != 200 ||
        studentsResponse.statusCode != 200 ||
        registersResponse.statusCode != 200) {
      throw Exception('Failed to load offsite analytics data');
    }

    final attendanceData = jsonDecode(attendanceResponse.body) as List<dynamic>;
    final studentsData = jsonDecode(studentsResponse.body) as List<dynamic>;
    final registersData = jsonDecode(registersResponse.body) as List<dynamic>;

    final Map<int, Map<String, dynamic>> studentsById = {
      for (final student in studentsData)
        if (student['student_id'] is int)
          student['student_id'] as int: {
            'name': '${(student['first_name'] ?? '').toString()} ${(student['last_name'] ?? '').toString()}'.trim(),
            'site': _siteNameFromId(student['site_combination_id']),
          },
    };

    final Map<int, String> registerDateById = {
      for (final register in registersData)
        if (register['register_id'] is int)
          register['register_id'] as int: (register['register_date'] ?? '').toString(),
    };

    List<Map<String, dynamic>> offsiteStudents = attendanceData
        .where((item) => item['on_site'] == false)
        .map((item) {
          final studentId = item['student_id'];
          final registerId = item['register_id'];
          if (studentId is! int || registerId is! int) return null;

          final studentInfo = studentsById[studentId];
          final studentName = (studentInfo?['name']?.toString().trim().isNotEmpty ?? false)
              ? studentInfo!['name'].toString()
              : 'Student $studentId';
          final site = studentInfo?['site']?.toString() ?? 'Unknown';
          final amPresent = item['am_present'] == true;
          final pmPresent = item['pm_present'] == true;
          final note = (item['note'] ?? '').toString().trim();

          return {
            'name': studentName,
            'reason': note.isEmpty ? 'No note provided' : note,
            'time': _timeLabel(amPresent, pmPresent),
            'site': site,
            'date': registerDateById[registerId] ?? 'Unknown date',
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    offsiteStudents.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));

    return offsiteStudents;
  } catch (e) {
    log('Error fetching offsite students: $e');
    return [];
  }
}

String _siteNameFromId(dynamic siteCombinationId) {
  switch (siteCombinationId) {
    case 1:
      return 'Elemore Hall';
    case 2:
      return 'Windlestone';
    case 3:
      return 'PACC';
    default:
      return 'Unknown';
  }
}

String _timeLabel(bool amPresent, bool pmPresent) {
  if (amPresent && pmPresent) return 'Morning & Afternoon';
  if (amPresent) return 'Morning';
  if (pmPresent) return 'Afternoon';
  return 'Not marked';
}
  Future<List<Map<String, dynamic>>> _fetchIncidents([
    String? siteFilter,
  ]) async {
    try {
      String url = '${AppConfig.apiUrl}/api/incidents/';

      // If a site is selected, use the site-specific endpoint
      if (siteFilter != null) {
        int? siteId = _getSiteId(siteFilter);
        if (siteId != null) {
          url = '${AppConfig.apiUrl}/api/incidents/site/$siteId/';
        }
      }

      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<Map<String, dynamic>> incidents = jsonData.map((item) {
          // Parse the date string
          String dateStr = item['incident_date'] ?? '';
          String formattedDate = dateStr.isNotEmpty
              ? DateTime.parse(dateStr).toString().split(' ')[0]
              : 'Unknown';

          return {
            'incident_id': item['incident_id'],
            'title': (item['note'] != null && item['note'].toString().isNotEmpty) ? item['note'] : (item['other_activity'] ?? 'Incident'),
            'date': formattedDate,
            'coordinator': 'Staff',
            'action_taken': item['action_taken'] ?? 'Pending',
            'outcome': item['outcome'],
            'status': item['status'],
          };
        }).toList();

        // Return only the most recent 5 incidents
        return incidents.take(5).toList();
      } else {
        throw Exception('Failed to load incidents');
      }
    } catch (e) {
      log('Error fetching incidents: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Row(
          children: [
            // ===============================================
            // LEFT PANEL: CLASS SELECTOR
            // ===============================================
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Button Removed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Classes",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            Text(
                              "Select a class to manage",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // SITES DROPDOWN
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blueGrey[200]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSite,
                        hint: Text(
                          'Sites',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'elemore_hall',
                            child: Text('Elemore Hall'),
                          ),
                          DropdownMenuItem(
                            value: 'windlestone',
                            child: Text('Windlestone'),
                          ),
                          DropdownMenuItem(value: 'pacc', child: Text('PACC')),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedSite = value;
                            _classesData = _fetchClasses(_selectedSite);
                            _incidentsData = _fetchIncidents(_selectedSite);
                          });
                        },
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: Colors.white,
                        iconEnabledColor: Colors.blueGrey[600],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // GRID OF CLASSES
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _classesData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading classes: ${snapshot.error}',
                              ),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No classes found'),
                            );
                          }

                          final classes = snapshot.data!;
                          return GridView.builder(
                            itemCount: classes.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.6,
                                ),
                            itemBuilder: (context, index) {
                              final cls = classes[index];
                              return InkWell(
                                onTap: () => _openClassRegister(cls),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (cls['color'] as Color).withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (cls['color'] as Color).withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.class_,
                                        color: cls['color'],
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cls['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blueGrey[800],
                                        ),
                                      ),
                                      Text(
                                        _getSiteLabel(cls['site_combination_id']),
                                        style: TextStyle(
                                          color: Colors.blueGrey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${cls['students']} Students",
                                        style: TextStyle(
                                          color: Colors.blueGrey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showAllClassesPopup,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: Colors.blueGrey[200]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "View All Classes",
                          style: TextStyle(
                            color: Colors.blueGrey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===============================================
            // RIGHT PANEL: LOGS & ANALYTICS
            // ===============================================
            Expanded(
              child: Column(
                children: [
                  // LOGS CARD
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 16, 16, 8),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Incidents",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await AuthService.logout();
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        size: 15,
                                        color: Colors.red[600],
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _incidentsData,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading incidents: ${snapshot.error}',
                                    ),
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                    child: Text('No incidents found'),
                                  );
                                }

                                final incidents = snapshot.data!;
                                return ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: incidents.map((incident) {
                                    final statusColor =
                                        incident['status'] == 'Complete'
                                        ? Colors.green
                                        : incident['status'] == 'Requires Review'
                                        ? Colors.orange
                                        : Colors.blueGrey;
                                    return _buildLogItem(
                                      incident['title'],
                                      incident['date'],
                                      incident['coordinator'],
                                      incident['status'] ?? 'Pending',
                                      statusColor,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to the new full page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LogsPage(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text("View Logs"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const CreateLogModal(),
                                    );
                                    if (result == true) {
                                      _refreshData();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text("Add Log"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ANALYTICS CARD
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Off-Site students",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),

                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OffsiteStudentsPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  backgroundColor: Colors.blue[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "View All",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
const SizedBox(height: 16),

Expanded(
  child: FutureBuilder<List<Map<String, dynamic>>>(
    future: _offsiteStudentsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
       
      final students = snapshot.data ?? [];
      print('Snapshot connectionState: ${snapshot.connectionState}');
      print('Snapshot hasData: ${snapshot.hasData}');
      print('Snapshot data: ${snapshot.data}');
      print('Snapshot hasError: ${snapshot.hasError}');
      print('Snapshot error: ${snapshot.error}');
      final elemore = students.where((s) => s['site'] == 'Elemore Hall').toList();
      final windlestone = students.where((s) => s['site'] == 'Windlestone').toList();
      final pacc = students.where((s) => s['site'] == 'PACC').toList();
      final unknown = students.where((s) => s['site'] == 'Unknown').toList();

      return Row(
        children: [
          _buildSiteColumn("Elemore", elemore),
          _buildSiteColumn("Windlestone", windlestone),
          _buildSiteColumn("PACC", pacc),
          _buildSiteColumn("Unknown", unknown),
        ],
      );
    },
  ),
),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(
    String title,
    String date,
    String coord,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              date,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              coord,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSiteColumn(String title, List<Map<String, dynamic>> students) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: students.isEmpty
              ? const Text("None", style: TextStyle(fontSize: 12))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        s['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
}

class _AllClassesFullscreenDialog extends StatefulWidget {
  const _AllClassesFullscreenDialog({
    required this.fetchClasses,
    required this.getSiteLabel,
    required this.onClassTap,
  });

  final Future<List<Map<String, dynamic>>> Function() fetchClasses;
  final String Function(int? siteId) getSiteLabel;
  final Future<void> Function(
    Map<String, dynamic> cls,
    BuildContext navigationContext,
  ) onClassTap;

  @override
  State<_AllClassesFullscreenDialog> createState() =>
      _AllClassesFullscreenDialogState();
}

class _AllClassesFullscreenDialogState extends State<_AllClassesFullscreenDialog> {
  late Future<List<Map<String, dynamic>>> _allClassesFuture;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allClassesFuture = widget.fetchClasses();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _allClassesFuture = widget.fetchClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('All Classes'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _allClassesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load classes from the database.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final classes = snapshot.data ?? [];
            if (classes.isEmpty) {
              return const Center(child: Text('No classes found in the database.'));
            }

            final query = _searchQuery.trim().toLowerCase();

final filteredClasses = classes.where((cls) {
  if (query.isEmpty) return true;

  final className = (cls['class_name'] ?? '').toString().toLowerCase();
  final classId = (cls['class_id'] ?? '').toString().toLowerCase();
  final staffId = (cls['staff_id'] ?? '').toString().toLowerCase();
  final siteId = cls['site_combination_id'];
  final siteLabel =
      widget.getSiteLabel(siteId is int ? siteId : null).toLowerCase();

  // Support: "class id 12", "classid 12", "class 12"
  final classMatch = RegExp(r'^class\s*id?\s*:?\s*(.+)$').firstMatch(query);
  if (classMatch != null) {
    final classIdQuery = classMatch.group(1)?.trim() ?? '';
    if (classIdQuery.isEmpty) return true;
    return classId.contains(classIdQuery);
  }

  // Support: "staff id 4", "staffid 4", "staff 4"
  final staffMatch = RegExp(r'^staff\s*id?\s*:?\s*(.+)$').firstMatch(query);
  if (staffMatch != null) {
    final staffIdQuery = staffMatch.group(1)?.trim() ?? '';
    if (staffIdQuery.isEmpty) return true;
    return staffId.contains(staffIdQuery);
  }

  // General search
  return className.contains(query) ||
      classId.contains(query) ||
      staffId.contains(query) ||
      siteLabel.contains(query);
}).toList();

            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search classes, site, class ID or staff ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredClasses.isEmpty
                      ? Center(
                          child: Text(
                            'No classes match "$_searchQuery"',
                            style: TextStyle(color: Colors.blueGrey[600]),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredClasses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final cls = filteredClasses[index];
                            final classId = cls['class_id'];
                            final staffId = cls['staff_id'];
                            final siteId = cls['site_combination_id'];

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onClassTap(cls, context),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blueGrey.shade100,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cls['class_name'].toString(),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Class ID: $classId'),
                                    Text('Teacher (Staff ID): $staffId'),
                                    Text(
                                      'Site: ${widget.getSiteLabel(siteId is int ? siteId : null)}',
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to open register',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey.shade500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
