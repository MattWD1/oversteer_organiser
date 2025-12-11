// lib/screens/division_information_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;

import '../models/league.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';

class DivisionInformationPage extends StatefulWidget {
  final League league;
  final Division division;
  final EventRepository eventRepository;

  const DivisionInformationPage({
    super.key,
    required this.league,
    required this.division,
    required this.eventRepository,
  });

  @override
  State<DivisionInformationPage> createState() =>
      _DivisionInformationPageState();
}

class _DivisionInformationPageState extends State<DivisionInformationPage> {
  late Future<List<Event>> _futureEvents;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _futureEvents =
        widget.eventRepository.getEventsForDivision(widget.division.id);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildCalendar(List<Event> events) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    // Filter events for this month
    final monthEvents = events.where((event) {
      return event.date.year == _selectedMonth.year &&
          event.date.month == _selectedMonth.month;
    }).toList();

    // Create a map of day -> events
    final Map<int, List<Event>> eventsByDay = {};
    for (final event in monthEvents) {
      final day = event.date.day;
      eventsByDay.putIfAbsent(day, () => []).add(event);
    }

    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              // Weekday headers
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              // Calendar days
              ...List.generate(
                ((firstWeekday + daysInMonth) / 7).ceil(),
                (week) {
                  return TableRow(
                    children: List.generate(7, (dayOfWeek) {
                      final dayNumber = week * 7 + dayOfWeek - firstWeekday + 1;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(height: 50);
                      }

                      final hasEvents = eventsByDay.containsKey(dayNumber);
                      final dayEvents = eventsByDay[dayNumber] ?? [];

                      return GestureDetector(
                        onTap: hasEvents
                            ? () {
                                _showDayEvents(dayNumber, dayEvents);
                              }
                            : null,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: hasEvents ? Colors.red.shade50 : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  dayNumber.toString(),
                                  style: TextStyle(
                                    fontWeight: hasEvents
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: hasEvents ? Colors.red : null,
                                  ),
                                ),
                              ),
                              if (hasEvents)
                                Positioned(
                                  bottom: 4,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        // Add to calendar button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _exportToCalendar(events),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Add Events to Calendar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showDayEvents(int day, List<Event> events) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Events on $_selectedMonth/${_selectedMonth.month}/$day'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  leading: Text(
                    event.flagEmoji ?? '🏁',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(event.name),
                  subtitle: event.startTime != null
                      ? Text(
                          '${DateFormat('HH:mm').format(event.startTime!)} - ${event.endTime != null ? DateFormat('HH:mm').format(event.endTime!) : ''}',
                        )
                      : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToCalendar(List<Event> events) async {
    // Filter events that have start times
    final eventsWithTimes = events.where((e) => e.startTime != null).toList();

    if (eventsWithTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No events with times set. Long-press events to set times first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    int successCount = 0;
    int errorCount = 0;

    for (final event in eventsWithTimes) {
      try {
        final calendarEvent = calendar.Event(
          title: '${event.name} - ${widget.league.name}',
          description: widget.division.name,
          location: '',
          startDate: event.startTime!,
          endDate: event.endTime ?? event.startTime!.add(const Duration(hours: 2)),
        );

        final result = await calendar.Add2Calendar.addEvent2Cal(calendarEvent);
        if (result) {
          successCount++;
        } else {
          errorCount++;
        }
      } catch (e) {
        errorCount++;
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount > 0
              ? 'Successfully added $successCount event${successCount > 1 ? 's' : ''} to calendar${errorCount > 0 ? ' ($errorCount failed)' : ''}'
              : 'Failed to add events to calendar',
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: successCount > 0 ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildPointsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: const Text(
            'Race Format Points',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'Position',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'Points',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ..._buildPointsRows([25, 18, 15, 12, 10, 8, 6, 4, 2, 1]),
                ],
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text(
            'Sprint Format Points',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'Position',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'Points',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ..._buildPointsRows([8, 7, 6, 5, 4, 3, 2, 1]),
                ],
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text(
            'Qualifying Format Points',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade200),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'Position',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            'Points',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ..._buildPointsRows(List.filled(10, 0)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<TableRow> _buildPointsRows(List<int> points) {
    return List.generate(points.length, (index) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text('P${index + 1}'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                points[index].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.division.name} Information'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Event Calendar'),
            FutureBuilder<List<Event>>(
              future: _futureEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading events: ${snapshot.error}'),
                    ),
                  );
                }

                final events = snapshot.data ?? [];
                return _buildCalendar(events);
              },
            ),
            const Divider(height: 32, thickness: 2),
            _buildSectionHeader('Points Settings (Read-Only)'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'These are the current points settings for this division. Contact an admin to modify.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildPointsSettings(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
