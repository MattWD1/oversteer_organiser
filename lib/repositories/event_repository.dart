import '../models/event.dart';

abstract class EventRepository {
  Future<List<Event>> getEventsForCompetition(String competitionId);
}

class InMemoryEventRepository implements EventRepository {
  final List<Event> _events = [
    Event(
      id: 'ev1',
      competitionId: 'comp1',
      name: 'Round 1 - Bahrain',
      roundNumber: 1,
    ),
    Event(
      id: 'ev2',
      competitionId: 'comp1',
      name: 'Round 2 - Jeddah',
      roundNumber: 2,
    ),
    Event(
      id: 'ev3',
      competitionId: 'comp2',
      name: 'Round 1 - Silverstone',
      roundNumber: 1,
    ),
    Event(
      id: 'ev4',
      competitionId: 'comp3',
      name: 'Round 1 - Monza',
      roundNumber: 1,
    ),
  ];

  @override
  Future<List<Event>> getEventsForCompetition(String competitionId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // fake delay
    return _events.where((e) => e.competitionId == competitionId).toList();
  }
}
