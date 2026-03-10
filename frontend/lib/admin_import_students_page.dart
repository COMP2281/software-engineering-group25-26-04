import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'auth_service.dart';
import 'config.dart';

class AdminImportStudentsPage extends StatefulWidget {
  const AdminImportStudentsPage({super.key});

  @override
  State<AdminImportStudentsPage> createState() =>
      _AdminImportStudentsPageState();
}

class _AdminImportStudentsPageState extends State<AdminImportStudentsPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _preview;
  bool _showingPreview = false;

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) return;

      final bytes = result.files.first.bytes!;
      await _uploadForPreview(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting file: $e')));
    }
  }

  Future<void> _uploadForPreview(Uint8List bytes) async {
    setState(() => _isLoading = true);

    try {
      // Create a multipart request manually
      final uri = Uri.parse('${AppConfig.apiUrl}/api/students/import-preview');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(await AuthService.getHeaders());

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'students.csv'),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _preview = data;
          _showingPreview = true;
        });
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg = errorData['detail'] ?? 'Preview failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $errorMsg')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating preview: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importStudents() async {
    if (_preview == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text(
          'Import ${_preview!['valid']} valid students? '
          '${_preview!['invalid']} rows will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final rows = (_preview!['rows'] as List)
          .map(
            (r) => {
              'row': r['row'],
              'first_name': r['first_name'],
              'last_name': r['last_name'],
              'class_name': r['class_name'],
              'site_name': r['site_name'],
              'status': r['status'],
              'error': r['error'],
            },
          )
          .toList();

      final response = await ApiClient.post(
        '${AppConfig.apiUrl}/api/students/import',
        body: {'rows': rows},
        context: context,
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text(data['message'] ?? 'Import successful'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _preview = null;
                    _showingPreview = false;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Import failed')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Students')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showingPreview
          ? _buildPreview()
          : _buildUploadSection(),
    );
  }

  Widget _buildUploadSection() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Import Students from CSV',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'CSV format: First Name, Second Name, Class, Site',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Select CSV File'),
              onPressed: _selectFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_preview == null) {
      return const Center(child: Text('No preview available'));
    }

    final total = _preview!['total'] as int;
    final valid = _preview!['valid'] as int;
    final invalid = _preview!['invalid'] as int;
    final rows = _preview!['rows'] as List;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary: $total total rows',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '✓ Valid: $valid',
                style: const TextStyle(color: Colors.green),
              ),
              Text(
                '✗ Invalid: $invalid',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Row')),
                  DataColumn(label: Text('First Name')),
                  DataColumn(label: Text('Last Name')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('Site')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Error')),
                ],
                rows: rows.map((row) {
                  final isValid = row['status'] == 'valid';
                  return DataRow(
                    color: WidgetStateProperty.resolveWith(
                      (states) =>
                          isValid ? Colors.green.shade50 : Colors.red.shade50,
                    ),
                    cells: [
                      DataCell(Text('${row['row']}')),
                      DataCell(Text(row['first_name'] ?? '')),
                      DataCell(Text(row['last_name'] ?? '')),
                      DataCell(Text(row['class_name'] ?? '')),
                      DataCell(Text(row['site_name'] ?? '')),
                      DataCell(Text(isValid ? '✓' : '✗')),
                      DataCell(Text(row['error'] ?? '', maxLines: 2)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _preview = null;
                    _showingPreview = false;
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: valid > 0 ? _importStudents : null,
                  child: const Text('Import All Valid'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
