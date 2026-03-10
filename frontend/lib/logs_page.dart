import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'api_client.dart';
import 'config.dart';
import 'log_modal.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late Future<List<Map<String, dynamic>>> _logsFuture;
  Timer? _pollingTimer;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
    _searchController = TextEditingController();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _normalizeNamesList(dynamic rawValue) {
    if (rawValue is! List) {
      return const [];
    }

    final normalized = <String>[];
    for (final item in rawValue) {
      final text = '${item ?? ''}'.trim();
      if (text.isNotEmpty) {
        normalized.add(text);
      }
    }
    return normalized;
  }

  Future<Map<int, String>> _fetchStaffNamesById() async {
    final response = await ApiClient.get('${AppConfig.apiUrl}/api/staff/');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch staff');
    }

    final staffData = jsonDecode(response.body) as List<dynamic>;
    return {
      for (final item in staffData)
        if (item['staff_id'] is int)
          item['staff_id'] as int: '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim(),
    };
  }

  Future<Map<int, String>> _fetchStudentNamesById() async {
    final response = await ApiClient.get('${AppConfig.apiUrl}/api/students/');
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch students');
    }

    final studentData = jsonDecode(response.body) as List<dynamic>;
    return {
      for (final item in studentData)
        if (item['student_id'] is int)
          item['student_id'] as int: '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim(),
    };
  }

  Future<Map<String, List<String>>> _fetchIncidentParticipants(
    int incidentId,
    Map<int, String> staffNamesById,
    Map<int, String> studentNamesById,
  ) async {
    final responses = await Future.wait([
      ApiClient.get('${AppConfig.apiUrl}/api/staff-incidents/incident/$incidentId'),
      ApiClient.get('${AppConfig.apiUrl}/api/student-incidents/incident/$incidentId'),
    ]);

    final staffResponse = responses[0];
    final studentResponse = responses[1];

    final staffInvolved = <String>[];
    if (staffResponse.statusCode == 200) {
      final staffIncidentData = jsonDecode(staffResponse.body) as List<dynamic>;
      for (final item in staffIncidentData) {
        final staffId = item['staff_id'];
        if (staffId is int) {
          final name = staffNamesById[staffId];
          if (name != null && name.trim().isNotEmpty) {
            staffInvolved.add(name);
          }
        }
      }
    }

    final pupilsInvolved = <String>[];
    if (studentResponse.statusCode == 200) {
      final studentIncidentData = jsonDecode(studentResponse.body) as List<dynamic>;
      for (final item in studentIncidentData) {
        final studentId = item['student_id'];
        if (studentId is int) {
          final name = studentNamesById[studentId];
          if (name != null && name.trim().isNotEmpty) {
            pupilsInvolved.add(name);
          }
        }
      }
    }

    return {
      'staff_involved': staffInvolved,
      'pupils_involved': pupilsInvolved,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    try {
      final response = await ApiClient.get(
        '${AppConfig.apiUrl}/api/incidents/',
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch incidents');
      }

      final jsonData = jsonDecode(response.body) as List<dynamic>;
      final staffNamesById = await _fetchStaffNamesById();
      final studentNamesById = await _fetchStudentNamesById();

      final enrichedLogs = await Future.wait(
        jsonData.map((item) async {
          final logItem = Map<String, dynamic>.from(item);
          final incidentId = logItem['incident_id'];
          if (incidentId is! int) {
            logItem['staff_involved'] = <String>[];
            logItem['pupils_involved'] = <String>[];
            return logItem;
          }

          final participants = await _fetchIncidentParticipants(
            incidentId,
            staffNamesById,
            studentNamesById,
          );
          logItem.addAll(participants);
          return logItem;
        }),
      );

      return enrichedLogs;
    } catch (e) {
      log('Error fetching logs: $e');
      rethrow;
    }
  }

  void _refresh() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  Future<void> _deleteLog(int incidentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this log entry? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiClient.delete(
        '${AppConfig.apiUrl}/api/incidents/$incidentId',
        context: context,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log deleted successfully')),
          );
          _refresh();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete log: ${response.body}')),
          );
        }
      }
    } catch (e) {
      log('Error deleting log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editLog(Map<String, dynamic> incident) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateLogModal(existingIncident: incident),
    );

    if (result == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Page'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading logs: ${snapshot.error}'),
              ),
            );
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No logs found'));
          }

          final query = _searchQuery.trim().toLowerCase();
          final filteredLogs = logs.where((logItem) {
            if (query.isEmpty) return true;

            final note = (logItem['note'] ?? '').toString().toLowerCase();
            final otherActivity = (logItem['other_activity'] ?? '')
                .toString()
                .toLowerCase();
            final pupilsInvolved = _normalizeNamesList(
              logItem['pupils_involved'],
            ).join(' ').toLowerCase();
            final staffInvolved = _normalizeNamesList(
              logItem['staff_involved'],
            ).join(' ').toLowerCase();

            return note.contains(query) ||
                otherActivity.contains(query) ||
                pupilsInvolved.contains(query) ||
                staffInvolved.contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search brief description, pupils involved, or staff involved',
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
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No logs match "$_searchQuery"',
                          style: TextStyle(color: Colors.blueGrey[600]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredLogs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final logItem = filteredLogs[index];
                          final noteForTitle = (logItem['note'] ?? '').toString();
                          final otherActivity = (logItem['other_activity'] ?? '').toString();
                          final title = noteForTitle.isNotEmpty ? noteForTitle : (otherActivity.isNotEmpty ? otherActivity : 'Incident');
                          final dateText = (logItem['incident_date'] ?? '').toString();
                          final outcome = (logItem['outcome'] ?? '').toString();
                          final status = (logItem['status'] ?? 'Pending').toString();
                          final note = (logItem['note'] ?? '').toString();
                          final incidentId = logItem['incident_id'] as int;
                          final pupilsInvolved = _normalizeNamesList(
                            logItem['pupils_involved'],
                          );
                          final staffInvolved = _normalizeNamesList(
                            logItem['staff_involved'],
                          );

                          final statusColor = status == 'Complete'
                              ? Colors.green
                              : status == 'Requires Review'
                              ? Colors.orange
                              : Colors.blueGrey;

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.blueGrey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Date: $dateText',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueGrey[500],
                                  ),
                                ),
                                if (outcome.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Outcome: $outcome',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey[600],
                                    ),
                                  ),
                                ],
                                if (staffInvolved.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Staff involved: ${staffInvolved.join(', ')}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey[600],
                                    ),
                                  ),
                                ],
                                if (pupilsInvolved.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pupils involved: ${pupilsInvolved.join(', ')}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blueGrey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _editLog(logItem),
                                      icon: const Icon(Icons.edit_outlined, size: 22),
                                      label: const Text('Edit', style: TextStyle(fontSize: 15)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue[700],
                                        side: BorderSide(color: Colors.blue.shade200),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => _deleteLog(incidentId),
                                      icon: const Icon(Icons.delete_outline, size: 22),
                                      label: const Text('Delete', style: TextStyle(fontSize: 15)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[600],
                                        side: BorderSide(color: Colors.red.shade200),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
