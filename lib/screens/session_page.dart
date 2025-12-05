import 'package:flutter/material.dart';
import '../models/event.dart';

class SessionPage extends StatelessWidget {
  final Event event;

  const SessionPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
      ),
      body: Center(
        child: Text(
          'Session / Results screen for:\n${event.name}\n\n'
          'Later this becomes your results input UI (grid, finish positions, etc).',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
