import 'package:flutter/material.dart';

class StreaksScreen extends StatelessWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streaks')),
      body: const Center(
        child: Text('Streak tracking will appear here'),
      ),
    );
  }
}
