import 'package:flutter/material.dart';
import '../models/competition.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';
import 'session_page.dart';

class DivisionPage extends StatefulWidget {
  final Competition competition;
  final EventRepository eventRepository;

  const DivisionPage({
    super.key,
    required this.competition,
    required this.eventRepository,
  });

  @override
  State<DivisionPage> createState() => _DivisionPageState();
}

class _DivisionPageState extends State<DivisionPage> {
  late Future<List<Event>> _futureEvents;

  @override
  void initState() {
    super.initState();
    _futureEvents =
        widget.eventRepository.getEventsForCompetition(widget.competition.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.competition.name),
      ),
      body: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading events: ${snapshot.error}'),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(
              child: Text('No events for this competition yet.'),
            );
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return ListTile(
                title: Text(event.name),
                subtitle: Text('Round ${event.roundNumber}'),
                trailing: const Icon(Icons.flag),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionPage(event: event),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
