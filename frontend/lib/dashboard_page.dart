import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'logs_page.dart';
import 'log_modal.dart';
import 'analytics_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Data for your classes
  final List<Map<String, dynamic>> _classes = [
    {"name": "Biology 101", "students": 24, "color": Colors.green},
    {"name": "Chemistry", "students": 18, "color": Colors.orange},
    {"name": "Physics A", "students": 22, "color": Colors.purple},
    {"name": "Maths Adv", "students": 30, "color": Colors.blue},
    {"name": "English Lit", "students": 25, "color": Colors.red},
    {"name": "History", "students": 19, "color": Colors.brown},
    {"name": "Comp Sci", "students": 28, "color": Colors.indigo},
    {"name": "Art & Design", "students": 15, "color": Colors.pink},
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: Scaffold(
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
                        // Removed the IconButton here
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // GRID OF CLASSES
                    Expanded(
                      child: GridView.builder(
                        itemCount: _classes.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.6, 
                        ),
                        itemBuilder: (context, index) {
                          final cls = _classes[index];
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
                    flex: 2, 
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
                          Text("Logs", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      _buildLogItem("System Update", "24 Jan", "Admin", "Completed", Colors.green),
                                      _buildLogItem("User Request", "23 Jan", "Sarah", "Awaiting Action", Colors.orange),
                                      _buildLogItem("Backup Failed", "22 Jan", "System", "Incomplete", Colors.red),
                                      _buildLogItem("New Registration", "21 Jan", "Mike", "Completed", Colors.green),
                                      _buildLogItem("Security Check", "20 Jan", "Admin", "Completed", Colors.green),
                                    ],
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
                              Expanded(child: ElevatedButton(onPressed: () {
                                showDialog(
                                context: context,
                                builder: (context) => const CreateLogModal(),
                              );
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
                             children: [
                               Text("Analytics", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
                               TextButton(
                                 onPressed: () {
                                  Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsPage()),
    );
                                 }, 
                                 style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), backgroundColor: Colors.blue[50], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                                 child: Text("View All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[700]))
                               )
                             ],
                           ),
                           
                           const SizedBox(height: 16),

                           // --- FL_CHART IMPLEMENTATION ---
                           Expanded(
                             child: BarChart(
                               BarChartData(
                                 alignment: BarChartAlignment.spaceAround,
                                 maxY: 20,
                                 gridData: const FlGridData(show: false),
                                 borderData: FlBorderData(show: false),
                                 barTouchData: BarTouchData(
                                   enabled: true,
                                   touchTooltipData: BarTouchTooltipData(
                                     tooltipBgColor: Colors.blueGrey.shade800,
                                     tooltipPadding: const EdgeInsets.all(8),
                                     tooltipMargin: 8,
                                     getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                       return BarTooltipItem(
                                         rod.toY.round().toString(),
                                         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                       );
                                     },
                                   ),
                                 ),
                                 titlesData: FlTitlesData(
                                   show: true,
                                   bottomTitles: AxisTitles(
                                     sideTitles: SideTitles(
                                       showTitles: true,
                                       getTitlesWidget: (double value, TitleMeta meta) {
                                          const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12);
                                          Widget text;
                                          switch (value.toInt()) {
                                            case 0: text = const Text('M', style: style); break;
                                            case 1: text = const Text('T', style: style); break;
                                            case 2: text = const Text('W', style: style); break;
                                            case 3: text = const Text('T', style: style); break;
                                            case 4: text = const Text('F', style: style); break;
                                            case 5: text = const Text('S', style: style); break;
                                            case 6: text = const Text('S', style: style); break;
                                            default: text = const Text('', style: style);
                                          }
                                          return SideTitleWidget(axisSide: meta.axisSide, child: text);
                                       },
                                     ),
                                   ),
                                   leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                   topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                   rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                 ),
                                 barGroups: [
                                   _makeGroupData(0, 12, Colors.indigo[200]!),
                                   _makeGroupData(1, 16, Colors.indigo[300]!),
                                   _makeGroupData(2, 18, Colors.indigo[400]!),
                                   _makeGroupData(3, 14, Colors.indigo[300]!),
                                   _makeGroupData(4, 10, Colors.indigo[200]!),
                                   _makeGroupData(5, 5, Colors.red[300]!),
                                   _makeGroupData(6, 4, Colors.red[400]!),
                                 ],
                               ),
                             ),
                           ),

                           const SizedBox(height: 12),
                           Row(children: [const Icon(Icons.trending_down, color: Colors.red, size: 20), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Logs down 30%", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)), Text("Activity is lower than usual.", style: TextStyle(color: Colors.red[300], fontSize: 11))])]),
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

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22, 
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20, 
            color: Colors.grey[100], 
          ),
        ),
      ],
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