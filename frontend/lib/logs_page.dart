import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

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

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/api/incidents/'),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch incidents');
      }

      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.map((item) => Map<String, dynamic>.from(item)).toList();
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
      final response = await http.delete(
        Uri.parse('${AppConfig.apiUrl}/api/incidents/$incidentId'),
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final logItem = logs[index];
              final noteForTitle = (logItem['note'] ?? '').toString();
              final otherActivity = (logItem['other_activity'] ?? '').toString();
              final title = noteForTitle.isNotEmpty ? noteForTitle : (otherActivity.isNotEmpty ? otherActivity : 'Incident');
              final dateText = (logItem['incident_date'] ?? '').toString();
              final outcome = (logItem['outcome'] ?? '').toString();
              final status = (logItem['status'] ?? 'Pending').toString();
              final note = (logItem['note'] ?? '').toString();
              final incidentId = logItem['incident_id'] as int;

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
                    // Title row with status badge
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
                    // Date
                    Text(
                      'Date: $dateText',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey[500],
                      ),
                    ),
                    // Outcome
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
                    // Note
                    if (note.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Action buttons row
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
          );
        },
      ),
    );
  }
}
