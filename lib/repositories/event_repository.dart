import '../models/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEventsForDivision(String divisionId);

  /// Creates a new event and returns its ID
  Future<String> createEvent({
    required String divisionId,
    required String name,
    required DateTime date,
    String? flagEmoji,
  });

  /// Deletes an event by ID
  Future<void> deleteEvent(String eventId);
}

class InMemoryEventRepository implements EventRepository {
  final List<Event> _events = [
    Event(
      id: 'event1',
      divisionId: 'div1',
      name: 'Bahrain GP',
      date: DateTime(2025, 3, 10),
    ),
    Event(
      id: 'event2',
      divisionId: 'div1',
      name: 'Jeddah GP',
      date: DateTime(2025, 3, 24),
    ),
    Event(
      id: 'event3',
      divisionId: 'div2',
      name: 'Monza GP',
      date: DateTime(2025, 4, 7),
    ),
    Event(
      id: 'event4',
      divisionId: 'div3',
      name: 'Spa GP',
      date: DateTime(2025, 5, 12),
    ),
  ];

  @override
  Future<List<Event>> getEventsForDivision(String divisionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _events.where((e) => e.divisionId == divisionId).toList();
  }

  @override
  Future<String> createEvent({
    required String divisionId,
    required String name,
    required DateTime date,
    String? flagEmoji,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Generate a unique ID
    final newId = 'event_${DateTime.now().millisecondsSinceEpoch}';

    // Create and add the new event
    final newEvent = Event(
      id: newId,
      divisionId: divisionId,
      name: name,
      date: date,
      flagEmoji: flagEmoji,
    );

    _events.add(newEvent);

    return newId;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _events.removeWhere((e) => e.id == eventId);
  }
}
