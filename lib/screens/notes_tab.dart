import 'package:flutter/material.dart';

/// Notes tab - placeholder for future implementation
class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grade_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Soon available',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            // const SizedBox(height: 12),
            // Text(
            //   'La consultation des notes sera bientôt disponible',
            //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //         color: Colors.grey[500],
            //       ),
            //   textAlign: TextAlign.center,
            // ),
          ],
        ),
      ),
    );
  }
}
