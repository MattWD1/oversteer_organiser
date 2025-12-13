// lib/screens/division_information_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;

import '../models/league.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../repositories/event_repository.dart';
import '../theme/app_theme.dart';

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
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.league.themeColor,
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
                            color: hasEvents ? widget.league.themeColor.withValues(alpha: 0.1) : null,
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
                                    color: hasEvents ? widget.league.themeColor : null,
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
                                      decoration: BoxDecoration(
                                        color: widget.league.themeColor,
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
            onPressed: () => _showEventSelectionDialog(events),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Add Events to Calendar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.league.themeColor,
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

  void _showEventSelectionDialog(List<Event> events) {
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

    // Create a map to track selected events
    final Map<String, bool> selectedEvents = {
      for (var event in eventsWithTimes) event.id: true, // All selected by default
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Events to Add'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose which events to add to your calendar:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: eventsWithTimes.length,
                        itemBuilder: (context, index) {
                          final event = eventsWithTimes[index];
                          final isSelected = selectedEvents[event.id] ?? false;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedEvents[event.id] = value ?? false;
                              });
                            },
                            activeColor: widget.league.themeColor,
                            title: Row(
                              children: [
                                if (event.flagEmoji != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      event.flagEmoji!,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                Expanded(child: Text(event.name)),
                              ],
                            ),
                            subtitle: Text(
                              '${DateFormat('MMM d, yyyy').format(event.date)} at ${DateFormat('HH:mm').format(event.startTime!)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Get selected events
                    final selected = eventsWithTimes
                        .where((event) => selectedEvents[event.id] == true)
                        .toList();

                    if (selected.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one event'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();
                    _exportToCalendar(selected);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.league.themeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Calendar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportToCalendar(List<Event> selectedEvents) async {
    if (selectedEvents.isEmpty) return;

    // Show progress dialog
    int currentIndex = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adding Events to Calendar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Event ${currentIndex + 1} of ${selectedEvents.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedEvents[currentIndex].name,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / selectedEvents.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.league.themeColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap "Add Event" to open your calendar app.\nSave the event, then return here to continue.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                if (currentIndex > 0)
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    final event = selectedEvents[currentIndex];
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(dialogContext);

                    try {
                      final calendarEvent = calendar.Event(
                        title: '${event.name} - ${widget.league.name}',
                        description: widget.division.name,
                        location: '',
                        startDate: event.startTime!,
                        endDate: event.endTime ?? event.startTime!.add(const Duration(hours: 2)),
                      );

                      await calendar.Add2Calendar.addEvent2Cal(calendarEvent);

                      // Move to next event or close dialog
                      if (currentIndex < selectedEvents.length - 1) {
                        setDialogState(() {
                          currentIndex++;
                        });
                      } else {
                        // All events processed
                        navigator.pop();

                        if (!mounted) return;

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('All ${selectedEvents.length} events have been processed!'),
                            duration: const Duration(seconds: 3),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error adding ${event.name}: $e'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.league.themeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(currentIndex < selectedEvents.length - 1 ? 'Add Event & Continue' : 'Add Final Event'),
                ),
              ],
            );
          },
        );
      },
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
    return AppTheme(
      primaryColor: widget.league.themeColor,
      child: Scaffold(
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
      ),
    );
  }
}
