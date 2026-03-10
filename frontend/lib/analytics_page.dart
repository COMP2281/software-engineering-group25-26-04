import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'config.dart';

class OffsiteStudentsPage extends StatefulWidget {
  const OffsiteStudentsPage({super.key});

  @override
  State<OffsiteStudentsPage> createState() => _OffsiteStudentsPageState();
}

class _OffsiteStudentsPageState extends State<OffsiteStudentsPage> {
  String? _selectedSite;
  late Future<List<Map<String, dynamic>>> _offsiteFuture;
  Timer? _pollingTimer;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _offsiteFuture = _fetchOffsiteStudents();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Future<List<Map<String, dynamic>>> _fetchOffsiteStudents() async {
    try {
      final attendanceResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/attendance/',
      );
      final studentsResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/students/',
      );
      final registersResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/registers/',
      );

      if (attendanceResponse.statusCode != 200 ||
          studentsResponse.statusCode != 200 ||
          registersResponse.statusCode != 200) {
        throw Exception('Failed to load offsite analytics data');
      }

      final attendanceData =
          jsonDecode(attendanceResponse.body) as List<dynamic>;
      final studentsData = jsonDecode(studentsResponse.body) as List<dynamic>;
      final registersData = jsonDecode(registersResponse.body) as List<dynamic>;

      final Map<int, Map<String, dynamic>> studentsById = {
        for (final student in studentsData)
          if (student['student_id'] is int)
            student['student_id'] as int: {
              'name':
                  '${(student['first_name'] ?? '').toString()} ${(student['last_name'] ?? '').toString()}'
                      .trim(),
              'site': _siteNameFromId(student['site_combination_id']),
            },
      };

      final Map<int, String> registerDateById = {
        for (final register in registersData)
          if (register['register_id'] is int)
            register['register_id'] as int: (register['register_date'] ?? '')
                .toString(),
      };

      final offsiteStudents = attendanceData
          .where((item) => item['on_site'] == false)
          .map((item) {
            final studentId = item['student_id'];
            final registerId = item['register_id'];
            if (studentId is! int || registerId is! int) return null;

            final studentInfo = studentsById[studentId];
            final studentName =
                (studentInfo?['name']?.toString().trim().isNotEmpty ?? false)
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

      offsiteStudents.sort(
        (a, b) => b['date'].toString().compareTo(a['date'].toString()),
      );

      return offsiteStudents;
    } catch (e) {
      log('Error fetching offsite students: $e');
      rethrow;
    }
  }

  void _refresh() {
    setState(() {
      _offsiteFuture = _fetchOffsiteStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Offsite Students'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _offsiteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading offsite students: ${snapshot.error}',
                ),
              ),
            );
          }

          final students = snapshot.data ?? [];
          final filteredStudents = students.where((s) {
            final matchesSite =
                _selectedSite == null || s['site'] == _selectedSite;
            final matchesSearch =
                _searchQuery.isEmpty ||
                s['name'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            return matchesSite && matchesSearch;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Row with Site Filter and Search Bar
                Row(
                  children: [
                    // Site Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueGrey[200]!,
                            width: 1.2,
                          ),
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
                    ),
                    const SizedBox(width: 12),
                    // Search Bar
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueGrey[200]!,
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by student name',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Offsite Students List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? const Center(child: Text('No offsite students found'))
                      : ListView.separated(
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
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'].toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          student['reason'].toString(),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${student['time']} • ${student['date']} • ${student['site']}',
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
          );
        },
      ),
    );
  }
}
