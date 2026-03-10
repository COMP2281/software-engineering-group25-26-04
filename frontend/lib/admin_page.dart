import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_class_management_page.dart';
import 'admin_import_students_page.dart';
import 'admin_user_management_page.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'config.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> staff = [];
  List<dynamic> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final staffResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/staff/',
        context: context,
      );
      if (!mounted) return;
      final classesResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/classes/',
        context: context,
      );

      if (!mounted) return;

      if (staffResponse.statusCode == 200 &&
          classesResponse.statusCode == 200) {
        setState(() {
          staff = jsonDecode(staffResponse.body) as List;
          classes = jsonDecode(classesResponse.body) as List;
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

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: SingleChildScrollView(
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
                // Header with logout button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin Panel",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        Text(
                          "Manage school operations",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey[500],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _logout(context),
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
                const SizedBox(height: 32),
                // Import Students Section
                Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import Students'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: const AdminImportStudentsPage(),
                          ),
                        ),
                      ).then((_) {
                        // Refresh data after import
                        _loadData();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Staff Members Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Staff Members",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminUserManagementPage(),
                              ),
                            )
                            .then((_) => _loadData());
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (staff.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No staff members',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: staff.length > 5 ? 5 : staff.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final s = staff[index];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s['first_name']} ${s['last_name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      s['email'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                s['role'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 32),
                // Classes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Classes",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminClassManagementPage(),
                              ),
                            )
                            .then((_) => _loadData());
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (classes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No classes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: classes.length > 5 ? 5 : classes.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey[300]),
                      itemBuilder: (context, index) {
                        final c = classes[index];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['class_name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _getTeacherName(c['staff_id'] ?? 0),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _getSiteName(c['site_combination_id'] ?? 0),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 32),
                // Go to Dashboard button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const DashboardPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.blueGrey[200]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Go to Dashboard",
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
      ),
    );
  }
}
