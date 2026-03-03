import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

import 'config.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
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
      return jsonData.map((item) {
        final dateText = (item['incident_date'] ?? '').toString();
        final title = (item['action'] ?? item['other_activity'] ?? 'Incident')
            .toString();
        return {
          'incident_id': item['incident_id'],
          'title': title,
          'date': dateText,
          'outcome': (item['outcome'] ?? 'Pending').toString(),
          'note': (item['note'] ?? '').toString(),
        };
      }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Page'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
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
              final outcome = logItem['outcome'].toString();
              final statusColor = outcome == 'Resolved'
                  ? Colors.green
                  : outcome == 'Pending'
                  ? Colors.orange
                  : Colors.blueGrey;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            logItem['title'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            outcome,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Date: ${logItem['date']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    if (logItem['note'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        logItem['note'].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                    ],
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
