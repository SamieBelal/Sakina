import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NamesScreen extends ConsumerStatefulWidget {
  const NamesScreen({super.key});

  /// Test-only: clears the process-global "viewed this session" latch. The
  @override
  ConsumerState<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends ConsumerState<NamesScreen> {
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
