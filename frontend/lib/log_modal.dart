import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'api_client.dart';
import 'config.dart';

class CreateLogModal extends StatefulWidget {
  final Map<String, dynamic>? existingIncident;

  const CreateLogModal({super.key, this.existingIncident});

  bool get isEditing => existingIncident != null;

  @override
  State<CreateLogModal> createState() => _CreateLogModalState();
}

class _CreateLogModalState extends State<CreateLogModal> {
  // --- Controllers & State ---
  final TextEditingController _coordinatorController = TextEditingController();
  final TextEditingController _staffInputController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _sheetController = TextEditingController();
  
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _actionsTakenController = TextEditingController();
  final TextEditingController _outcomeController = TextEditingController();

  bool _isAuthorSameAsStaff = false;
  DateTime _selectedDate = DateTime.now();
  
  String? _selectedSite;
  final List<String> _sites = ["Site 1", "Site 2", "Site 3"];

  final List<String> _staffInvolved = [];
  final List<String> _selectedReasons = [];
  final List<Map<String, String>> _students = [];
  List<String> _allStudentNames = [];
  List<String> _allStaffNames = [];

  final List<String> _incidentOptions = [
    "Anti Social Behaviour to pupils",
    "Anti Social Behaviour to staff",
    "Anti Social Behaviour to property",
    "Violence/ Aggression to pupils",
    "Violence/ Aggression to staff",
    "Property damage",
    "Smoking",
    "Substance abuse",
    "Absenting",
    "Absconding",
    "Refusal to participate in lesson",
    "Refusal to participate in Activity",
    "Positive report"
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    // Fetch all student names for autocomplete
    _fetchStudentNames();

    // Pre-fill fields when editing an existing incident
    final existing = widget.existingIncident;
    if (existing != null) {
      _descriptionController.text = (existing['note'] ?? '').toString();
      _actionsTakenController.text = (existing['action_taken'] ?? '').toString();
      _outcomeController.text = (existing['outcome'] ?? '').toString();
      _coordinatorController.text = (existing['duty_coordinator_id'] ?? '').toString();

      // Parse other_activity: could be an activity name, or comma-separated incident types
      final otherActivity = (existing['other_activity'] ?? '').toString();
      if (otherActivity.isNotEmpty) {
        final parts = otherActivity.split(', ');
        final matchedTypes = <String>[];
        final nonMatchedParts = <String>[];
        for (final part in parts) {
          if (_incidentOptions.contains(part)) {
            matchedTypes.add(part);
          } else {
            nonMatchedParts.add(part);
          }
        }
        if (matchedTypes.isNotEmpty) {
          _selectedReasons.addAll(matchedTypes);
        }
        if (nonMatchedParts.isNotEmpty) {
          _activityController.text = nonMatchedParts.join(', ');
        }
      }

      final dateStr = (existing['incident_date'] ?? '').toString();
      if (dateStr.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(dateStr);
          _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
        } catch (_) {}
      }

      final action = (existing['action'] ?? '').toString();
      if (action.startsWith('Author: ')) {
        _isAuthorSameAsStaff = true;
        _authorController.text = action.replaceFirst('Author: ', '');
      }

      // Fetch staff and students linked to this incident
      _loadLinkedData(existing['incident_id']);
    } else {
      // New log: start with one empty pupil row
      _students.add({'name': '', 'time': '', 'returned': '', 'duration': ''});
    }
  }

  Future<void> _loadLinkedData(dynamic incidentId) async {
    if (incidentId == null) return;
    print('>>> _loadLinkedData called with incidentId: $incidentId');

    try {
      // Fetch all staff names for lookup
      final staffResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/staff/',
      );
      print('>>> Staff response: ${staffResponse.statusCode}');
      final Map<int, String> staffNames = {};
      if (staffResponse.statusCode == 200) {
        final staffData = jsonDecode(staffResponse.body) as List<dynamic>;
        for (final s in staffData) {
          final id = s['staff_id'];
          if (id is int) {
            final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
            staffNames[id] = name.isNotEmpty ? name : 'Staff $id';
          }
        }
      }
      print('>>> Staff names loaded: ${staffNames.length}');

      // Fetch staff involved in this incident
      final staffIncResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/staff-incidents/incident/$incidentId',
      );
      print('>>> Staff-incidents response: ${staffIncResponse.statusCode}, body: ${staffIncResponse.body}');
      if (staffIncResponse.statusCode == 200) {
        final staffIncData = jsonDecode(staffIncResponse.body) as List<dynamic>;
        final names = staffIncData
            .map((si) => staffNames[si['staff_id']] ?? 'Staff ${si['staff_id']}')
            .toList();
        print('>>> Staff involved names: $names');
        if (names.isNotEmpty && mounted) {
          setState(() {
            _staffInvolved.addAll(names);
            if (_isAuthorSameAsStaff && _staffInvolved.isNotEmpty) {
              _authorController.text = _staffInvolved.first;
            }
          });
        }
      }

      // Fetch all student names for lookup
      final studentsResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/students/',
      );
      print('>>> Students response: ${studentsResponse.statusCode}');
      final Map<int, String> studentNames = {};
      if (studentsResponse.statusCode == 200) {
        final studentsData = jsonDecode(studentsResponse.body) as List<dynamic>;
        for (final s in studentsData) {
          final id = s['student_id'];
          if (id is int) {
            final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
            studentNames[id] = name.isNotEmpty ? name : 'Student $id';
          }
        }
      }
      print('>>> Student names loaded: ${studentNames.length}');

      // Fetch students involved in this incident
      final studentIncResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/student-incidents/incident/$incidentId',
      );
      print('>>> Student-incidents response: ${studentIncResponse.statusCode}, body: ${studentIncResponse.body}');
      if (studentIncResponse.statusCode == 200) {
        final studentIncData = jsonDecode(studentIncResponse.body) as List<dynamic>;
        print('>>> Student incident data count: ${studentIncData.length}');
        if (studentIncData.isNotEmpty && mounted) {
          setState(() {
            _students.clear();
            for (final si in studentIncData) {
              final studentId = si['student_id'];
              final name = studentNames[studentId] ?? 'Student $studentId';
              final time = (si['time'] ?? '').toString();
              final returned = si['returned'] == true ? 'Yes' : 'No';
              final duration = (si['duration_minutes'] ?? '').toString();
              _students.add({
                'name': name,
                'time': time.isNotEmpty && time != 'null' ? time.split('T').last.substring(0, 5) : '',
                'returned': returned,
                'duration': duration != 'null' ? duration : '',
              });
            }
            print('>>> _students after load: $_students');
          });
        }
      }
    } catch (e) {
      print('>>> ERROR in _loadLinkedData: $e');
      log('Error loading linked staff/students: $e');
    }
  }

  Future<void> _fetchStudentNames() async {
    try {
      final response = await ApiClient.get('${AppConfig.apiUrl}/api/students/');
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _allStudentNames = data.map((s) {
            return '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
          }).where((name) => name.isNotEmpty).toList()
            ..sort();
        });
      }

      final staffResponse = await ApiClient.get('${AppConfig.apiUrl}/api/staff/');
      if (staffResponse.statusCode == 200 && mounted) {
        final staffData = jsonDecode(staffResponse.body) as List<dynamic>;
        setState(() {
          _allStaffNames = staffData.map((s) {
            return '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
          }).where((name) => name.isNotEmpty).toList()
            ..sort();
        });
      }
    } catch (e) {
      log('Error fetching names: $e');
    }
  }

  @override
  void dispose() {
    _coordinatorController.dispose();
    _staffInputController.dispose();
    _authorController.dispose();
    _dateController.dispose();
    _activityController.dispose();
    _sheetController.dispose();
    _descriptionController.dispose();
    _actionsTakenController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  void _addStaffMember(String name) {
    if (name.trim().isNotEmpty) {
      setState(() {
        _staffInvolved.add(name.trim());
        _staffInputController.clear();
        if (_isAuthorSameAsStaff && _staffInvolved.isNotEmpty) {
          _authorController.text = _staffInvolved.first;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850, maxHeight: 950),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 30, thickness: 2),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopFields(),
                        const SizedBox(height: 20),
                        _buildStaffSection(),
                        const SizedBox(height: 25),
                        _buildReasonDropdown(),
                        const SizedBox(height: 25),
                        _buildStudentSection(),
                        const SizedBox(height: 25),
                        _buildDescriptionFields(),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text(
        widget.isEditing ? "EDIT LOG" : "DUTY COORDINATOR LOG",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTopFields() {
    return Column(
      children: [
        // Row 1: Coordinator, Site, Date
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _coordinatorController,
                decoration: const InputDecoration(
                  labelText: "Duty Coordinator", 
                  prefixIcon: Icon(Icons.assignment_ind),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  labelText: "Site",
                  border: OutlineInputBorder(),
                ),
                items: _sites.map((site) => DropdownMenuItem(value: site, child: Text(site))).toList(),
                onChanged: (val) => setState(() => _selectedSite = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: const InputDecoration(
                  labelText: "Date",
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Activity/Lesson and Sheet No.
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _activityController,
                decoration: const InputDecoration(
                  labelText: "Activity / Lesson",
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _sheetController,
                decoration: const InputDecoration(
                  labelText: "Sheet No.",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Staff Involved", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._staffInvolved.map((staff) => Chip(
                label: Text(staff),
                backgroundColor: Colors.blue.shade50,
                deleteIconColor: Colors.red.shade400,
                onDeleted: () => setState(() => _staffInvolved.remove(staff)),
              )),
              SizedBox(
                width: 200,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final available = _allStaffNames.where((name) => !_staffInvolved.contains(name));
                        if (textEditingValue.text.isEmpty) return available;
                        return available.where((name) =>
                          name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _staffInvolved.add(selection);
                        });
                        // Unfocus and clear the field to close dropdown
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        // Clear the field if the value matches an already-added staff
                        if (_staffInvolved.contains(controller.text)) {
                          controller.clear();
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Search staff...",
                            border: InputBorder.none,
                            isDense: true,
                            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                            prefixIconConstraints: const BoxConstraints(minWidth: 28),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 250,
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                                    ),
                                    title: Text(option, style: const TextStyle(fontSize: 14)),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Incident Types (Multi-select):", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _incidentOptions.map((option) {
            final isSelected = _selectedReasons.contains(option);
            return FilterChip(
              label: Text(option, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: Colors.blue.withOpacity(0.2),
              onSelected: (bool selected) {
                setState(() {
                  selected ? _selectedReasons.add(option) : _selectedReasons.remove(option);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pupils", style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _students.add({'name': '', 'time': '', 'returned': '', 'duration': ''})),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text("Add Pupil"),
            ),
          ],
        ),
        ..._students.asMap().entries.map((entry) {
          final i = entry.key;
          final student = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Autocomplete<String>(
                    initialValue: TextEditingValue(text: student['name'] ?? ''),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _allStudentNames;
                      }
                      return _allStudentNames.where((name) =>
                        name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _students[i]['name'] = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: "Search pupil...",
                          isDense: true,
                          prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey.shade500),
                          prefixIconConstraints: const BoxConstraints(minWidth: 24),
                        ),
                        onChanged: (val) => _students[i]['name'] = val,
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 250,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.green.shade100,
                                    child: Icon(Icons.school, size: 16, color: Colors.green.shade700),
                                  ),
                                  title: Text(option, style: const TextStyle(fontSize: 14)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: student['time'] ?? ''),
                    decoration: const InputDecoration(hintText: "Time", isDense: true),
                    onChanged: (val) => _students[i]['time'] = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: student['returned'] ?? ''),
                    decoration: const InputDecoration(hintText: "Ret.", isDense: true),
                    onChanged: (val) => _students[i]['returned'] = val,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: student['duration'] ?? ''),
                    decoration: const InputDecoration(hintText: "Dur.", isDense: true),
                    onChanged: (val) => _students[i]['duration'] = val,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => _students.removeAt(i)),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDescriptionFields() {
    return Column(
      children: [
        TextFormField(controller: _descriptionController, maxLines: 2, decoration: const InputDecoration(labelText: "Brief Description", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextFormField(controller: _actionsTakenController, maxLines: 2, decoration: const InputDecoration(labelText: "Actions taken by staff", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextFormField(controller: _outcomeController, maxLines: 2, decoration: const InputDecoration(labelText: "Outcome/ Consequence", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _authorController,
                readOnly: _isAuthorSameAsStaff,
                decoration: const InputDecoration(
                  labelText: "Duty Coordinator", 
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilterChip(
              label: const Text("Use Lead Staff"),
              selected: _isAuthorSameAsStaff,
              onSelected: (val) {
                setState(() {
                  _isAuthorSameAsStaff = val;
                  if (val && _staffInvolved.isNotEmpty) {
                    _authorController.text = _staffInvolved.first;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  bool _isLoading = false;

  Future<void> _submitLog() async {
    if (_coordinatorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Duty Coordinator')));
      return;
    }

    // Ask for log status before submitting
    final status = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.assignment_turned_in, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            const Text('Log Status'),
          ],
        ),
        content: const Text(
          'Is this log complete or does it require further review?',
          style: TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'Requires Review'),
            icon: const Icon(Icons.rate_review, color: Colors.orange),
            label: const Text('Requires Review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              side: BorderSide(color: Colors.orange.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'Complete'),
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    // User cancelled
    if (status == null) return;

    setState(() => _isLoading = true);

    final data = {
      "duty_coordinator_id": 1,
      "incident_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
      "class_id": null,
      "other_activity": _activityController.text.isNotEmpty ? _activityController.text : _selectedReasons.join(", "),
      "status": status,
      "action": _isAuthorSameAsStaff ? "Author: ${_authorController.text}" : null,
      "note": _descriptionController.text,
      "action_taken": _actionsTakenController.text,
      "outcome": _outcomeController.text,
    };

    try {
      final http.Response response;
      if (widget.isEditing) {
        final id = widget.existingIncident!['incident_id'];
        response = await ApiClient.put(
          '${AppConfig.apiUrl}/api/incidents/$id',
          body: data,
          context: context,
        );
      } else {
        response = await ApiClient.post(
          '${AppConfig.apiUrl}/api/incidents/',
          body: data,
          context: context,
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Get the incident ID (from response for new, from existing for edit)
        int? incidentId;
        if (widget.isEditing) {
          incidentId = widget.existingIncident!['incident_id'] as int;
        } else {
          try {
            final responseData = jsonDecode(response.body);
            incidentId = responseData['incident_id'] as int?;
          } catch (_) {}
        }

        // Sync staff and students if we have an incident ID
        if (incidentId != null) {
          await _syncStaffAndStudents(incidentId);
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save log: ${response.body}')));
        }
      }
    } catch (e) {
      log('Error saving log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncStaffAndStudents(int incidentId) async {
    print('>>> _syncStaffAndStudents called for incident $incidentId');
    print('>>> _staffInvolved: $_staffInvolved');
    print('>>> _students: $_students');
    try {
      // --- Sync Staff ---
      // Build name→ID lookup
      final staffResp = await ApiClient.get('${AppConfig.apiUrl}/api/staff/', context: context);
      final Map<String, int> staffNameToId = {};
      if (staffResp.statusCode == 200) {
        for (final s in jsonDecode(staffResp.body) as List<dynamic>) {
          final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
          if (name.isNotEmpty && s['staff_id'] is int) {
            staffNameToId[name] = s['staff_id'] as int;
          }
        }
      }
      print('>>> staffNameToId: $staffNameToId');

      // Delete existing staff-incident links
      final existingStaffResp = await ApiClient.get(
        '${AppConfig.apiUrl}/api/staff-incidents/incident/$incidentId',
        context: context,
      );
      if (existingStaffResp.statusCode == 200) {
        for (final si in jsonDecode(existingStaffResp.body) as List<dynamic>) {
          final delResp = await ApiClient.delete(
            '${AppConfig.apiUrl}/api/staff-incidents/${si['staff_id']}/$incidentId',
            context: context,
          );
          print('>>> Deleted staff link ${si['staff_id']}: ${delResp.statusCode}');
        }
      }

      // Create new staff-incident links
      for (final staffName in _staffInvolved) {
        final staffId = staffNameToId[staffName];
        print('>>> Creating staff link: name="$staffName" -> id=$staffId');
        if (staffId != null) {
          final createResp = await ApiClient.post(
            '${AppConfig.apiUrl}/api/staff-incidents/',
            body: {'staff_id': staffId, 'incident_id': incidentId},
            context: context,
          );
          print('>>> Staff link create response: ${createResp.statusCode} ${createResp.body}');
        }
      }

      // --- Sync Students ---
      // Build name→ID lookup
      final studentsResp = await ApiClient.get('${AppConfig.apiUrl}/api/students/', context: context);
      final Map<String, int> studentNameToId = {};
      if (studentsResp.statusCode == 200) {
        for (final s in jsonDecode(studentsResp.body) as List<dynamic>) {
          final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
          if (name.isNotEmpty && s['student_id'] is int) {
            studentNameToId[name] = s['student_id'] as int;
          }
        }
      }
      print('>>> studentNameToId keys: ${studentNameToId.keys.toList()}');

      // Delete existing student-incident links
      final existingStudentResp = await ApiClient.get(
        '${AppConfig.apiUrl}/api/student-incidents/incident/$incidentId',
        context: context,
      );
      if (existingStudentResp.statusCode == 200) {
        for (final si in jsonDecode(existingStudentResp.body) as List<dynamic>) {
          final delResp = await ApiClient.delete(
            '${AppConfig.apiUrl}/api/student-incidents/${si['student_id']}/$incidentId',
            context: context,
          );
          print('>>> Deleted student link ${si['student_id']}: ${delResp.statusCode}');
        }
      }

      // Create new student-incident links
      for (final student in _students) {
        final studentName = (student['name'] ?? '').toString();
        final studentId = studentNameToId[studentName];
        print('>>> Creating student link: name="$studentName" -> id=$studentId');
        if (studentId != null) {
          final createResp = await ApiClient.post(
            '${AppConfig.apiUrl}/api/student-incidents/',
            body: {
              'student_id': studentId,
              'incident_id': incidentId,
            },
            context: context,
          );
          print('>>> Student link create response: ${createResp.statusCode} ${createResp.body}');
        } else {
          print('>>> SKIPPED: no matching student_id for name "$studentName"');
        }
      }
    } catch (e) {
      print('>>> ERROR in _syncStaffAndStudents: $e');
      log('Error syncing staff/students: $e');
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: _isLoading ? null : _submitLog,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.isEditing ? "Update Log" : "Save Log Entry", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}