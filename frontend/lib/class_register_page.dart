import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'config.dart';

class ClassRegisterPage extends StatefulWidget {
  final String className;
  final int? classId;
  final bool isDemo;
  final List<Map<String, dynamic>> students;

  const ClassRegisterPage({
    super.key,
    required this.className,
    required this.classId,
    required this.isDemo,
    required this.students,
  });

  @override
  State<ClassRegisterPage> createState() => _ClassRegisterPageState();
}

class _ClassRegisterPageState extends State<ClassRegisterPage> {
  late final List<_RegisterStudent> _students;
  bool _isLoading = false;
  bool _isSaving = false;
  int? _registerId;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _students = widget.students
        .asMap()
        .entries
        .map(
          (entry) =>
              _RegisterStudent.fromMap(entry.value, fallbackId: entry.key + 1),
        )
        .toList();

    if (!widget.isDemo && (widget.classId ?? -1) > 0) {
      _loadExistingAttendance();
    }
  }

  @override
  void dispose() {
    for (final student in _students) {
      student.noteController.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<int?> _findTodayRegisterId() async {
    final classId = widget.classId;
    if (classId == null || classId <= 0) return null;

    try {
      final response = await ApiClient.get(
        '${AppConfig.apiUrl}/api/registers/class/$classId',
      );

      if (response.statusCode != 200) {
        return null;
      }

      final registers = jsonDecode(response.body) as List<dynamic>;
      final today = _formatDate(_selectedDate);

      for (final register in registers) {
        if (register['register_date']?.toString() == today) {
          final registerId = register['register_id'];
          if (registerId is int) return registerId;
        }
      }
    } catch (e) {
      log('Error finding today register: $e');
    }

    return null;
  }

  Future<int?> _createTodayRegister() async {
    final classId = widget.classId;
    if (classId == null || classId <= 0) return null;

    try {
      final response = await ApiClient.post(
        '${AppConfig.apiUrl}/api/registers/',
        body: {
          'register_date': _formatDate(_selectedDate),
          'class_id': classId,
        },
        context: context,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final created = jsonDecode(response.body);
        final registerId = created['register_id'];
        if (registerId is int) {
          return registerId;
        }
      }
    } catch (e) {
      log('Error creating register: $e');
    }

    return null;
  }

  Future<int?> _getOrCreateRegisterId() async {
    if (_registerId != null) return _registerId;

    final existing = await _findTodayRegisterId();
    if (existing != null) {
      _registerId = existing;
      return existing;
    }

    final created = await _createTodayRegister();
    _registerId = created;
    return created;
  }

  Future<void> _loadExistingAttendance() async {
    setState(() => _isLoading = true);

    try {
      final registerId = await _findTodayRegisterId();
      if (registerId == null) {
        return;
      }

      final attendanceResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/attendance/register/$registerId',
      );

      if (attendanceResponse.statusCode != 200) {
        return;
      }

      final attendanceData =
          jsonDecode(attendanceResponse.body) as List<dynamic>;
      final Map<int, Map<String, dynamic>> attendanceByStudent = {
        for (final item in attendanceData)
          if (item['student_id'] is int) item['student_id'] as int: item,
      };

      for (final student in _students) {
        final attendance = attendanceByStudent[student.studentId];
        if (attendance == null) continue;

        student.amPresent = attendance['am_present'] == true;
        student.pmPresent = attendance['pm_present'] == true;
        final onSite = attendance['on_site'] != false;
        student.offsite = !onSite;
        student.noteController.text = (attendance['note'] ?? '').toString();
      }

      _registerId = registerId;
    } catch (e) {
      log('Error loading attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load register data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _countAmPresent() {
    return _students.where((student) => student.amPresent).length;
  }

  int _countPmPresent() {
    return _students.where((student) => student.pmPresent).length;
  }

  int _countOffsite() {
    return _students.where((student) => student.offsite).length;
  }

  Future<void> _saveRegister() async {
    if (widget.isDemo || (widget.classId ?? -1) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo register updated locally.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final registerId = await _getOrCreateRegisterId();
      if (registerId == null) {
        throw Exception('Unable to create/find register for today');
      }

      final existingResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/attendance/register/$registerId',
        context: context,
      );

      final Set<int> existingStudentIds = {};
      if (existingResponse.statusCode == 200) {
        final existingData = jsonDecode(existingResponse.body) as List<dynamic>;
        for (final item in existingData) {
          final studentId = item['student_id'];
          if (studentId is int) {
            existingStudentIds.add(studentId);
          }
        }
      }

      int failedUpdates = 0;

      for (final student in _students) {
        final note = student.noteController.text.trim();
        final payload = {
          'am_present': student.amPresent,
          'pm_present': student.pmPresent,
          'on_site': !student.offsite,
          'note': student.offsite && note.isNotEmpty ? note : null,
        };

        final hasRecord = existingStudentIds.contains(student.studentId);
        final response = hasRecord
            ? await ApiClient.put(
                '${AppConfig.apiUrl}/api/attendance/$registerId/${student.studentId}',
                body: payload,
                context: context,
              )
            : await ApiClient.post(
                '${AppConfig.apiUrl}/api/attendance/',
                body: {
                  'register_id': registerId,
                  'student_id': student.studentId,
                  ...payload,
                },
                context: context,
              );

        if (response.statusCode != 200 && response.statusCode != 201) {
          failedUpdates++;
          log(
            'Failed attendance save for student ${student.studentId}: ${response.body}',
          );
        }
      }

      if (!mounted) return;

      if (failedUpdates == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Register saved to database.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Register saved with $failedUpdates failed attendance update(s).',
            ),
          ),
        );
      }
    } catch (e) {
      log('Error saving register: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving register: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _formatDate(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('${widget.className} Register'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: $today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isDemo
                  ? 'Demo mode (not saved to database)'
                  : 'Database mode (saved to attendance tables)',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryChip(
                  label: 'AM Present',
                  count: _countAmPresent(),
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'PM Present',
                  count: _countPmPresent(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                _SummaryChip(
                  label: 'Offsite',
                  count: _countOffsite(),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        itemCount: _students.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.blueGrey[100]),
                        itemBuilder: (context, index) {
                          final student = _students[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${student.name} (${student.studentId})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _CompactToggle(
                                  label: 'AM',
                                  value: student.amPresent,
                                  onChanged: (value) {
                                    setState(() => student.amPresent = value);
                                  },
                                ),
                                _CompactToggle(
                                  label: 'PM',
                                  value: student.pmPresent,
                                  onChanged: (value) {
                                    setState(() => student.pmPresent = value);
                                  },
                                ),
                                _CompactToggle(
                                  label: 'Offsite',
                                  value: student.offsite,
                                  onChanged: (value) {
                                    setState(() {
                                      student.offsite = value;
                                      if (!value) {
                                        student.noteController.clear();
                                      }
                                    });
                                  },
                                ),
                                if (student.offsite) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 220,
                                    child: TextFormField(
                                      controller: student.noteController,
                                      decoration: const InputDecoration(
                                        hintText: 'Note',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RegisterStudent {
  final int studentId;
  final String name;
  bool amPresent;
  bool pmPresent;
  bool offsite;
  final TextEditingController noteController;

  _RegisterStudent({
    required this.studentId,
    required this.name,
    required this.amPresent,
    required this.pmPresent,
    required this.offsite,
    required this.noteController,
  });

  factory _RegisterStudent.fromMap(
    Map<String, dynamic> map, {
    required int fallbackId,
  }) {
    final parsedId = int.tryParse(map['student_id']?.toString() ?? '');
    final studentId = parsedId ?? fallbackId;
    final rawName = (map['name'] ?? '').toString().trim();
    final name = rawName.isEmpty ? 'Student $studentId' : rawName;

    return _RegisterStudent(
      studentId: studentId,
      name: name,
      amPresent: true,
      pmPresent: true,
      offsite: false,
      noteController: TextEditingController(),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Checkbox(
          value: value,
          onChanged: (newValue) => onChanged(newValue ?? false),
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
