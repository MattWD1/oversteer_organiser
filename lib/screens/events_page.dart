import 'package:flutter/material.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';
import 'session_page.dart';
import 'issue_log_page.dart';
import 'penalties_page.dart';

enum EventSortOption { name, date }

class EventsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final Division division;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const EventsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.division,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> _futureEvents;
  EventSortOption _sortOption = EventSortOption.date;

  @override
  void initState() {
    super.initState();
    _futureEvents =
        widget.eventRepository.getEventsForDivision(widget.division.id);
  }

  List<Event> _sortedEvents(List<Event> source) {
    final events = List<Event>.from(source);

    if (_sortOption == EventSortOption.name) {
      events.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } else {
      // Sort by event date (soonest first)
      events.sort((a, b) => a.date.compareTo(b.date));
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events – ${widget.division.name}'),
      ),
      body: FutureBuilder<List<Event>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading events: ${snapshot.error}'),
            );
          }

          final originalEvents = snapshot.data ?? [];

          if (originalEvents.isEmpty) {
            return const Center(
              child: Text('No events for this division.'),
            );
          }

          final events = _sortedEvents(originalEvents);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events – ${widget.division.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Sort by:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<EventSortOption>(
                          value: _sortOption,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: EventSortOption.name,
                              child: Text('Name'),
                            ),
                            DropdownMenuItem(
                              value: EventSortOption.date,
                              child: Text('Date'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _sortOption = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];

                    return ListTile(
                      title: Text(event.name),
                      subtitle: Text('${event.date.toLocal()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Penalties',
                            icon: const Icon(Icons.gavel_outlined),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PenaltiesPage(
                                    event: event,
                                    driverRepository: widget.driverRepository,
                                    penaltyRepository:
                                        widget.penaltyRepository,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'View validation issues',
                            icon: const Icon(Icons.warning_amber_outlined),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => IssueLogPage(
                                    event: event,
                                    validationIssueRepository:
                                        widget.validationIssueRepository,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SessionPage(
                              event: event,
                              driverRepository: widget.driverRepository,
                              sessionResultRepository:
                                  widget.sessionResultRepository,
                              validationIssueRepository:
                                  widget.validationIssueRepository,
                              penaltyRepository: widget.penaltyRepository,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
