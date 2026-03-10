import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'class_register_page.dart';
import 'config.dart';
import 'login_page.dart';

/// Staff-only view: can only see and access classes, no dashboard features
class StaffClassesPage extends StatefulWidget {
  const StaffClassesPage({super.key});

  @override
  State<StaffClassesPage> createState() => _StaffClassesPageState();
}

class _StaffClassesPageState extends State<StaffClassesPage> {
  late Future<List<Map<String, dynamic>>> _allClassesFuture;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _allClassesFuture = _fetchAllClassesFromDb();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Reserved for a future site-filter flow on the staff classes page.
  // ignore: unused_element
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
      log('Error fetching class students: $e');
      return [];
    }
  }

  Future<void> _openClassRegister(Map<String, dynamic> cls) async {
    final classId = cls['class_id'];
    final List<Map<String, dynamic>> students = classId is int
        ? await _fetchStudentsForClass(classId)
        : <Map<String, dynamic>>[];

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassRegisterPage(
          className: cls['class_name'].toString(),
          classId: cls['class_id'] is int ? cls['class_id'] as int : null,
          isDemo: false,
          students: students,
        ),
      ),
    );
  }

  void _refresh() {
    setState(() {
      _allClassesFuture = _fetchAllClassesFromDb();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          title: const Text('My Classes'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueGrey[900],
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: _refresh,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
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
                return const Center(
                  child: Text('No classes found in the database.'),
                );
              }

              final query = _searchQuery.trim().toLowerCase();

              final filteredClasses = classes.where((cls) {
                if (query.isEmpty) return true;

                final className = (cls['class_name'] ?? '')
                    .toString()
                    .toLowerCase();
                final classId = (cls['class_id'] ?? '')
                    .toString()
                    .toLowerCase();
                final staffId = (cls['staff_id'] ?? '')
                    .toString()
                    .toLowerCase();
                final siteId = cls['site_combination_id'];
                final siteLabel = _getSiteLabel(
                  siteId is int ? siteId : null,
                ).toLowerCase();

                // Support: "class id 12", "classid 12", "class 12"
                final classMatch = RegExp(
                  r'^class\s*id?\s*:?\s*(.+)$',
                ).firstMatch(query);
                if (classMatch != null) {
                  final classIdQuery = classMatch.group(1)?.trim() ?? '';
                  if (classIdQuery.isEmpty) return true;
                  return classId.contains(classIdQuery);
                }

                // Support: "staff id 4", "staffid 4", "staff 4"
                final staffMatch = RegExp(
                  r'^staff\s*id?\s*:?\s*(.+)$',
                ).firstMatch(query);
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
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final cls = filteredClasses[index];
                              final classId = cls['class_id'];
                              final staffId = cls['staff_id'];
                              final siteId = cls['site_combination_id'];

                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openClassRegister(cls),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        'Site: ${_getSiteLabel(siteId is int ? siteId : null)}',
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
      ),
    );
  }
}
