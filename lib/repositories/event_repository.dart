import '../models/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEventsForDivision(String divisionId);
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
}
