import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'config.dart';

class AdminClassManagementPage extends StatefulWidget {
  const AdminClassManagementPage({super.key});

  @override
  State<AdminClassManagementPage> createState() =>
      _AdminClassManagementPageState();
}

class _AdminClassManagementPageState extends State<AdminClassManagementPage> {
  List<dynamic> classes = [];
  List<dynamic> staff = [];
  List<dynamic> sites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final classesResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/classes/',
        context: context,
      );
      final staffResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/staff/',
        context: context,
      );
      final sitesResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/sites/',
        context: context,
      );

      if (!mounted) return;

      if (classesResponse.statusCode == 200 &&
          staffResponse.statusCode == 200 &&
          sitesResponse.statusCode == 200) {
        setState(() {
          classes = jsonDecode(classesResponse.body) as List;
          staff = jsonDecode(staffResponse.body) as List;
          sites = jsonDecode(sitesResponse.body) as List;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      setState(() => isLoading = false);
    }
  }

  String _getTeacherName(int staffId) {
    try {
      final teacher = staff.firstWhere((s) => s['staff_id'] == staffId);
      return '${teacher['first_name']} ${teacher['last_name']}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getSiteName(int siteId) {
    final siteMap = {1: 'Elemore', 2: 'Windlestone', 3: 'PACC'};
    return siteMap[siteId] ?? 'Unknown';
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ClassFormDialog(
        staff: staff,
        sites: sites,
        siteNameMap: {1: 'Elemore', 2: 'Windlestone', 3: 'PACC'},
        onSaved: () {
          _loadData();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditDialog(dynamic classData) {
    showDialog(
      context: context,
      builder: (ctx) => _ClassFormDialog(
        classData: classData,
        staff: staff,
        sites: sites,
        siteNameMap: {1: 'Elemore', 2: 'Windlestone', 3: 'PACC'},
        onSaved: () {
          _loadData();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _deleteClass(dynamic classData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete "${classData['class_name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiClient.delete(
        '${AppConfig.apiUrl}/api/classes/${classData['class_id']}',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Class deleted')));
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Class Name')),
                    DataColumn(label: Text('Teacher')),
                    DataColumn(label: Text('Site')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: classes.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(Text(c['class_name'] ?? '')),
                        DataCell(Text(_getTeacherName(c['staff_id'] ?? 0))),
                        DataCell(
                          Text(_getSiteName(c['site_combination_id'] ?? 0)),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteClass(c),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}

class _ClassFormDialog extends StatefulWidget {
  final dynamic? classData;
  final List<dynamic> staff;
  final List<dynamic> sites;
  final Map<int, String> siteNameMap;
  final VoidCallback onSaved;

  const _ClassFormDialog({
    this.classData,
    required this.staff,
    required this.sites,
    required this.siteNameMap,
    required this.onSaved,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  late TextEditingController classNameController;
  int? selectedTeacherId;
  int? selectedSiteId;
  bool isLoading = false;
  List<dynamic> enrolledStudents = [];
  List<dynamic> availableStudents = [];
  bool loadingStudents = false;

  @override
  void initState() {
    super.initState();
    classNameController = TextEditingController(
      text: widget.classData?['class_name'] ?? '',
    );
    selectedTeacherId = widget.classData?['staff_id'];
    selectedSiteId = widget.classData?['site_combination_id'];

    if (selectedTeacherId == null && widget.staff.isNotEmpty) {
      selectedTeacherId = widget.staff.first['staff_id'];
    }
    if (selectedSiteId == null && widget.sites.isNotEmpty) {
      selectedSiteId = widget.sites.first['combination_id'] ?? 1;
    }

    // Load enrolled students if editing
    if (widget.classData != null) {
      _loadEnrolledStudents();
    }
  }

  @override
  void dispose() {
    classNameController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrolledStudents() async {
    if (widget.classData == null) return;
    try {
      final classId = widget.classData['class_id'] as int;
      final response = await ApiClient.get(
        '${AppConfig.apiUrl}/api/class-students/class/$classId',
        context: context,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          enrolledStudents = jsonDecode(response.body) as List;
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _loadAvailableStudents() async {
    if (selectedSiteId == null) return;
    try {
      final response = await ApiClient.get(
        '${AppConfig.apiUrl}/api/students',
        context: context,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final allStudents = jsonDecode(response.body) as List;
        // Filter to only students from the selected site
        final filteredStudents = allStudents
            .where((s) => s['site_combination_id'] == selectedSiteId)
            .toList();

        // Filter out already enrolled students
        final enrolledIds = enrolledStudents
            .map((e) => e['student_id'])
            .toSet();
        availableStudents = filteredStudents
            .where((s) => !enrolledIds.contains(s['student_id']))
            .toList();
      }
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _removeStudent(int studentId) async {
    if (widget.classData == null) return;
    try {
      final classId = widget.classData['class_id'] as int;
      final response = await ApiClient.delete(
        '${AppConfig.apiUrl}/api/class-students/$classId/$studentId',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          enrolledStudents.removeWhere((s) => s['student_id'] == studentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed from class')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _enrollStudent(int studentId) async {
    if (widget.classData == null) return;
    try {
      final classId = widget.classData['class_id'] as int;
      final response = await ApiClient.post(
        '${AppConfig.apiUrl}/api/class-students/',
        body: {'class_id': classId, 'student_id': studentId},
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Reload students
        await _loadEnrolledStudents();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Student enrolled')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddStudentDialog() async {
    await _loadAvailableStudents();

    if (!mounted) return;

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available students to enroll')),
      );
      return;
    }

    int? selectedStudentId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student to Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a student:'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              isExpanded: true,
              hint: const Text('Choose a student'),
              value: selectedStudentId,
              items: availableStudents
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s['student_id'] as int,
                      child: Text('${s['first_name']} ${s['last_name']}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                selectedStudentId = val;
                (ctx as dynamic).setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: selectedStudentId != null
                ? () {
                    _enrollStudent(selectedStudentId!);
                    Navigator.pop(ctx);
                  }
                : null,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClass() async {
    if (classNameController.text.isEmpty ||
        selectedTeacherId == null ||
        selectedSiteId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final body = {
        'class_name': classNameController.text.trim(),
        'staff_id': selectedTeacherId,
        'site_combination_id': selectedSiteId,
      };

      final response = widget.classData == null
          ? await ApiClient.post('${AppConfig.apiUrl}/api/classes/', body: body)
          : await ApiClient.put(
              '${AppConfig.apiUrl}/api/classes/${widget.classData['class_id']}',
              body: body,
            );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.classData == null ? 'Class created' : 'Class updated',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classData == null ? 'Create Class' : 'Edit Class'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: classNameController,
              decoration: const InputDecoration(labelText: 'Class Name'),
            ),
            const SizedBox(height: 16),
            const Text('Teacher:'),
            DropdownButton<int>(
              isExpanded: true,
              value: selectedTeacherId,
              items: widget.staff
                  .map(
                    (s) => DropdownMenuItem<int>(
                      value: s['staff_id'] as int,
                      child: Text('${s['first_name']} ${s['last_name']}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedTeacherId = val),
            ),
            const SizedBox(height: 16),
            const Text('Site:'),
            DropdownButton<int>(
              isExpanded: true,
              value: selectedSiteId,
              items: [
                const DropdownMenuItem(value: 1, child: Text('Elemore')),
                const DropdownMenuItem(value: 2, child: Text('Windlestone')),
                const DropdownMenuItem(value: 3, child: Text('PACC')),
              ],
              onChanged: (val) => setState(() => selectedSiteId = val),
            ),
            const SizedBox(height: 24),
            // Enrolled Students section (only show when editing)
            if (widget.classData != null) ...[
              const Text('Enrolled Students:'),
              const SizedBox(height: 8),
              if (enrolledStudents.isEmpty)
                const Text(
                  'No students enrolled yet',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: enrolledStudents.map((student) {
                    return Chip(
                      label: Text(
                        '${student['first_name']} ${student['last_name']}',
                      ),
                      onDeleted: () =>
                          _removeStudent(student['student_id'] as int),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                  onPressed: _showAddStudentDialog,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isLoading ? null : _saveClass,
          child: Text(widget.classData == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
