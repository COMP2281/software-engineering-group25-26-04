import 'package:flutter/material.dart';

class CreateLogModal extends StatelessWidget {
  const CreateLogModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400, // Fixed width for tablet
        height: 300, // Fixed height or remove for dynamic size
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Add Log",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 20),

            // TODO: Add your content here later
            const Center(child: Text("Content goes here...")),
          ],
        ),
      ),
    );
  }
}