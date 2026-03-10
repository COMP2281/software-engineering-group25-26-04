import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'config.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  List<dynamic> staff = [];
  List<dynamic> roles = [];
  List<dynamic> sites = [];
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
      final rolesResponse = await ApiClient.get(
        '${AppConfig.apiUrl}/api/access-levels/',
        context: context,
      );

      if (!mounted) return;

      if (staffResponse.statusCode == 200 && rolesResponse.statusCode == 200) {
        setState(() {
          staff = jsonDecode(staffResponse.body) as List;
          roles = jsonDecode(rolesResponse.body) as List;
          // Hardcoded sites to match the three available sites
          sites = [
            {
              'combination_id': 1,
              'site1': true,
              'site2': false,
              'site3': false,
            },
            {
              'combination_id': 2,
              'site1': false,
              'site2': true,
              'site3': false,
            },
            {
              'combination_id': 3,
              'site1': false,
              'site2': false,
              'site3': true,
            },
          ];
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

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateStaffDialog(
        roles: roles,
        sites: sites,
        onStaffCreated: () {
          _loadData();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditDialog(dynamic staffMember) {
    showDialog(
      context: context,
      builder: (ctx) => _EditStaffDialog(
        staff: staffMember,
        roles: roles,
        sites: sites,
        onUpdated: () {
          _loadData();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
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
                    DataColumn(label: Text('First Name')),
                    DataColumn(label: Text('Last Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: staff.map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s['first_name'] ?? '')),
                        DataCell(Text(s['last_name'] ?? '')),
                        DataCell(Text(s['email'] ?? '')),
                        DataCell(Text(s['role'] ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditDialog(s),
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

class _CreateStaffDialog extends StatefulWidget {
  final List<dynamic> roles;
  final List<dynamic> sites;
  final VoidCallback onStaffCreated;

  const _CreateStaffDialog({
    required this.roles,
    required this.sites,
    required this.onStaffCreated,
  });

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  String? selectedRole;
  Set<int> selectedSites = {};
  bool isLoading = false;
  Map<int, String> siteNameMap = {};

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    selectedRole = widget.roles.isNotEmpty ? widget.roles.first['role'] : null;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _createStaff() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create staff first
      final staffResponse = await ApiClient.post(
        '${AppConfig.apiUrl}/api/staff/',
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'role': selectedRole,
        },
      );

      if (!mounted) return;

      if (staffResponse.statusCode != 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create staff')));
        return;
      }

      final staffData = jsonDecode(staffResponse.body) as Map<String, dynamic>;
      final staffId = staffData['staff_id'] as int;

      // Create user account
      final userResponse = await ApiClient.post(
        '${AppConfig.apiUrl}/api/users/',
        body: {'staff_id': staffId, 'password': password},
      );

      if (!mounted) return;

      if (userResponse.statusCode == 201) {
        // Assign sites if any selected
        for (final siteId in selectedSites) {
          await ApiClient.post(
            '${AppConfig.apiUrl}/api/staff-sites/',
            body: {'staff_id': staffId, 'site_combination_id': siteId},
          );
        }

        if (mounted) {
          widget.onStaffCreated();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff created successfully')),
          );
        }
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

  String _getSiteName(dynamic site) {
    if (site['site1'] == true) return 'Elemore Hall';
    if (site['site2'] == true) return 'Windlestone';
    if (site['site3'] == true) return 'PACC';
    return 'Unknown Site';
  }

  List<dynamic> _getDedupSites() {
    final seen = <int>{};
    final result = <dynamic>[];
    for (final site in widget.sites) {
      final siteId = site['combination_id'] as int;
      if (!seen.contains(siteId)) {
        seen.add(siteId);
        result.add(site);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Staff'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Set Password (min 8 characters)',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Assign Sites:'),
            const SizedBox(height: 8),
            ..._getDedupSites().map((site) {
              final siteId = site['combination_id'] as int;
              final siteName = _getSiteName(site);
              return CheckboxListTile(
                title: Text(siteName),
                value: selectedSites.contains(siteId),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSites.add(siteId);
                    } else {
                      selectedSites.remove(siteId);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedRole,
              items: widget.roles
                  .map(
                    (r) => DropdownMenuItem<String>(
                      value: r['role'] as String,
                      child: Text(r['role'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => selectedRole = val ?? selectedRole),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isLoading ? null : _createStaff,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _EditStaffDialog extends StatefulWidget {
  final dynamic staff;
  final List<dynamic> roles;
  final List<dynamic> sites;
  final VoidCallback onUpdated;

  const _EditStaffDialog({
    required this.staff,
    required this.roles,
    required this.sites,
    required this.onUpdated,
  });

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  late String selectedRole;
  Set<int> selectedSites = {};
  bool isLoading = false;
  late TextEditingController passwordController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    firstNameController = TextEditingController(
      text: widget.staff['first_name'] ?? '',
    );
    lastNameController = TextEditingController(
      text: widget.staff['last_name'] ?? '',
    );
    emailController = TextEditingController(text: widget.staff['email'] ?? '');
    selectedRole = widget.staff['role'];
    _loadUserSites();
  }

  @override
  void dispose() {
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSites() async {
    try {
      final response = await ApiClient.get(
        '${AppConfig.apiUrl}/api/staff-sites/staff/${widget.staff['staff_id']}',
        context: context,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final sites = jsonDecode(response.body) as List;
        setState(() {
          selectedSites = sites
              .map((s) => s['site_combination_id'] as int)
              .toSet();
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _updateStaff() async {
    setState(() => isLoading = true);

    try {
      // Update staff info (name, email, role)
      await ApiClient.put(
        '${AppConfig.apiUrl}/api/staff/${widget.staff['staff_id']}',
        body: {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'role': selectedRole,
        },
      );

      // Update password if custom password was entered
      if (passwordController.text.isNotEmpty) {
        await ApiClient.put(
          '${AppConfig.apiUrl}/api/users/${widget.staff['staff_id']}',
          body: {'password': passwordController.text},
        );
      }

      // Sync site assignments
      final staffId = widget.staff['staff_id'] as int;

      // Get current sites from the UI state
      final previousSites = <int>{};
      try {
        if (!mounted) return;
        final response = await ApiClient.get(
          '${AppConfig.apiUrl}/api/staff-sites/staff/$staffId',
          context: context,
        );
        if (response.statusCode == 200) {
          final sites = jsonDecode(response.body) as List;
          previousSites.addAll(
            sites.map((s) => s['site_combination_id'] as int),
          );
        }
      } catch (e) {
        // Ignore errors loading current sites
      }

      // Add new sites
      for (final siteId in selectedSites) {
        if (!previousSites.contains(siteId)) {
          await ApiClient.post(
            '${AppConfig.apiUrl}/api/staff-sites/',
            body: {'staff_id': staffId, 'site_combination_id': siteId},
          );
        }
      }

      // Remove deleted sites
      for (final siteId in previousSites) {
        if (!selectedSites.contains(siteId)) {
          await ApiClient.delete(
            '${AppConfig.apiUrl}/api/staff-sites/$staffId/$siteId',
          );
        }
      }

      if (mounted) {
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff updated successfully')),
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

  // Reserved for a future admin-triggered password reset flow.
  // ignore: unused_element
  Future<void> _resetPassword() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiClient.post(
        '${AppConfig.apiUrl}/api/users/${widget.staff['staff_id']}/reset-password',
        body: {},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newPassword = data['new_password'] as String;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Password Reset'),
            content: Text(
              'New password: $newPassword\nCopy this password now.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
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

  String _getSiteName(dynamic site) {
    if (site['site1'] == true) return 'Elemore Hall';
    if (site['site2'] == true) return 'Windlestone';
    if (site['site3'] == true) return 'PACC';
    return 'Unknown Site';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Staff'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            const Text('Role:'),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedRole,
              items: widget.roles
                  .map(
                    (r) => DropdownMenuItem<String>(
                      value: r['role'] as String,
                      child: Text(r['role'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  setState(() => selectedRole = val ?? selectedRole),
            ),
            const SizedBox(height: 16),
            const Text('Assigned Sites:'),
            const SizedBox(height: 8),
            ..._getDedupSites().map((site) {
              final siteId = site['combination_id'] as int;
              final siteName = _getSiteName(site);
              return CheckboxListTile(
                title: Text(siteName),
                value: selectedSites.contains(siteId),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedSites.add(siteId);
                    } else {
                      selectedSites.remove(siteId);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Leave empty to keep current password',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: isLoading ? null : _updateStaff,
          child: const Text('Update'),
        ),
      ],
    );
  }

  List<dynamic> _getDedupSites() {
    final seen = <int>{};
    final result = <dynamic>[];
    for (final site in widget.sites) {
      final siteId = site['combination_id'] as int;
      if (!seen.contains(siteId)) {
        seen.add(siteId);
        result.add(site);
      }
    }
    return result;
  }
}
