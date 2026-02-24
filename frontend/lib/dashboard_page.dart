import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'logs_page.dart';
import 'log_modal.dart';
import 'analytics_page.dart';
import 'config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<List<Map<String, dynamic>>> _classesData;
  late Future<List<Map<String, dynamic>>> _incidentsData;
  String? _selectedSite;
  String? _selectedOffsiteSite;

  final List<Color> _colors = [
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.blue,
    Colors.red,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
  ];

    @override
  void initState() {
    super.initState();
    _classesData = _fetchClasses(_selectedSite);
    _incidentsData = _fetchIncidents();
  }

  void _refreshData() {
    setState(() {
      _classesData = _fetchClasses(_selectedSite);
      _incidentsData = _fetchIncidents(_selectedSite);
    });
  }

  int? _getSiteId(String? siteName) {
    switch (siteName) {
      case 'elemore_hall':
        return 1;
      case 'windlestone':
        return 2;
      case 'pacc':
        return 3;
      default:
        return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchClasses([String? siteFilter]) async {
    try {
      String url = '${AppConfig.apiUrl}/api/classes/';
      
      // If a site is selected, use the site-specific endpoint
      if (siteFilter != null) {
        int? siteId = _getSiteId(siteFilter);
        if (siteId != null) {
          url = '${AppConfig.apiUrl}/api/classes/site/$siteId/';
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<Map<String, dynamic>> classes = [];

        for (int index = 0; index < jsonData.length; index++) {
          final item = jsonData[index];
          
          // Fetch student count for this class
          int studentCount = 0;
          try {
            final studentsResponse = await http.get(
              Uri.parse('${AppConfig.apiUrl}/api/class-students/class/${item['class_id']}/'),
            );
            
            if (studentsResponse.statusCode == 200) {
              List<dynamic> studentsData = jsonDecode(studentsResponse.body);
              studentCount = studentsData.length;
            }
          } catch (e) {
            log('Error fetching student count for class ${item['class_id']}: $e');
          }

          classes.add({
            'class_id': item['class_id'],
            'name': item['class_name'],
            'students': studentCount,
            'color': _colors[index % _colors.length],
          });
        }
        
        return classes;
      } else {
        throw Exception('Failed to load classes');
      }
    } catch (e) {
      log('Error fetching classes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchIncidents([String? siteFilter]) async {
    try {
      String url = '${AppConfig.apiUrl}/api/incidents/';
      
      // If a site is selected, use the site-specific endpoint
      if (siteFilter != null) {
        int? siteId = _getSiteId(siteFilter);
        if (siteId != null) {
          url = '${AppConfig.apiUrl}/api/incidents/site/$siteId/';
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        List<Map<String, dynamic>> incidents = jsonData.map((item) {
          // Parse the date string
          String dateStr = item['incident_date'] ?? '';
          String formattedDate = dateStr.isNotEmpty 
              ? DateTime.parse(dateStr).toString().split(' ')[0]
              : 'Unknown';

          return {
            'incident_id': item['incident_id'],
            'title': item['action'] ?? item['other_activity'] ?? 'Incident',
            'date': formattedDate,
            'coordinator': 'Staff',
            'action_taken': item['action_taken'] ?? 'Pending',
            'outcome': item['outcome'],
          };
        }).toList();
        
        // Return only the most recent 5 incidents
        return incidents.take(5).toList();
      } else {
        throw Exception('Failed to load incidents');
      }
    } catch (e) {
      log('Error fetching incidents: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Row(
          children: [
            
            // ===============================================
            // LEFT PANEL: CLASS SELECTOR
            // ===============================================
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (Button Removed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Classes",
                              style: TextStyle(
                                fontSize: 28, 
                                fontWeight: FontWeight.w700, 
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            Text(
                              "Select a class to manage",
                              style: TextStyle(fontSize: 16, color: Colors.blueGrey[500]),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh),
                          color: Colors.blueGrey[600],
                          tooltip: 'Refresh data',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // SITES DROPDOWN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey[200]!, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedSite,
                        hint: Text(
                          'Sites',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'elemore_hall',
                            child: Text('Elemore Hall'),
                          ),
                          DropdownMenuItem(
                            value: 'windlestone',
                            child: Text('Windlestone'),
                          ),
                          DropdownMenuItem(
                            value: 'pacc',
                            child: Text('PACC'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedSite = value;
                            _classesData = _fetchClasses(_selectedSite);
                            _incidentsData = _fetchIncidents(_selectedSite);
                          });
                        },
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: Colors.white,
                        iconEnabledColor: Colors.blueGrey[600],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // GRID OF CLASSES
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _classesData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error loading classes: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No classes found'));
                          }

                          final classes = snapshot.data!;
                          return GridView.builder(
                            itemCount: classes.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.6,
                            ),
                            itemBuilder: (context, index) {
                              final cls = classes[index];
                              return InkWell(
                                onTap: () {},
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: (cls['color'] as Color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (cls['color'] as Color).withOpacity(0.3),
                                      width: 1
                                    )
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.class_, color: cls['color'], size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        cls['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blueGrey[800]
                                        ),
                                      ),
                                      Text(
                                        "${cls['students']} Students",
                                        style: TextStyle(
                                          color: Colors.blueGrey[500],
                                          fontSize: 12
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          side: BorderSide(color: Colors.blueGrey[200]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("View All Classes", style: TextStyle(color: Colors.blueGrey[700], fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // ===============================================
            // RIGHT PANEL: LOGS & ANALYTICS
            // ===============================================
            Expanded(
              child: Column(
                children: [
                  // LOGS CARD
                  Expanded(
                    flex: 1, 
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 16, 16, 8),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Incidents", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
                              IconButton(
                                onPressed: _refreshData,
                                icon: const Icon(Icons.refresh),
                                color: Colors.blueGrey[600],
                                tooltip: 'Refresh incidents',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _incidentsData,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Error loading incidents: ${snapshot.error}'));
                                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Text('No incidents found'));
                                }

                                final incidents = snapshot.data!;
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: incidents.map((incident) {
                                    final statusColor = incident['outcome'] == 'Resolved' 
                                        ? Colors.green 
                                        : incident['outcome'] == 'Pending' 
                                        ? Colors.orange 
                                        : Colors.red;
                                    return _buildLogItem(
                                      incident['title'],
                                      incident['date'],
                                      incident['coordinator'],
                                      incident['outcome'] ?? 'Pending',
                                      statusColor,
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: ElevatedButton(onPressed: () {
                                // Navigate to the new full page
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const LogsPage())
                                );
                              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)), elevation: 0), child: const Text("View Logs"))),
                              const SizedBox(width: 12),
                              Expanded(child: ElevatedButton(onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => const CreateLogModal(),
                                );
                                if (result == true) {
                                  _refreshData();
                                }
                              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), child: const Text("Add Log"))),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  // ANALYTICS CARD
                  Expanded(
                    flex: 1, 
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           // Header
                           Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                       Text(
                                               "OffSite students",
                                                style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blueGrey[800],
                                             ),
                                            ),
                                 const SizedBox(height: 8),

                                 Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                           decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blueGrey[200]!, width: 1.2),
                                          borderRadius: BorderRadius.circular(10),
                                           color: Colors.white,
                                          ),
                                          child: DropdownButton<String>(
                                          value: _selectedOffsiteSite,
                                          hint: Text(
                                          'Filter by Site',
                                          style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blueGrey[600],
                                           ),
                                         ),
                                         underline: const SizedBox(),
                                           items: const [
                                      DropdownMenuItem(
                                                      value: 'elemore_hall',
                                                      child: Text('Elemore Hall'),
                                                       ),
                                      DropdownMenuItem(
                                                      value: 'windlestone',
                                                      child: Text('Windlestone'),
                                                       ),
                                      DropdownMenuItem(
                                                      value: 'pacc',
                                                      child: Text('PACC'),
                                                      ),
                                                      ],
                                       onChanged: (value) {
                                      setState(() {
                                      _selectedOffsiteSite = value;
              });
            },
          ),
        ),
      ],
    ),

    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OffsiteStudentsPage()),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        "View All",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    ),
  ],
),
                           
                           

                         ]
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildLogItem(String title, String date, String coord, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))), 
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 1, child: Text(date, style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]))),
          Expanded(flex: 1, child: Text(coord, style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]))),
          Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))),
        ],
      ),
    );
  }
}