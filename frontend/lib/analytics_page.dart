import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Dark text for the simplistic look
        elevation: 1,
      ),
      body: Container(), // Empty body for you to fill later
    );
  }
}