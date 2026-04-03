import 'package:flutter/material.dart';

class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('99 Names of Allah')),
      body: const Center(
        child: Text('Names browser will appear here'),
      ),
    );
  }
}
