import '../models/penalty.dart';

abstract class PenaltyRepository {
  List<Penalty> getPenaltiesForEvent(String eventId);
  void addPenalty(Penalty penalty);
  void removePenalty(String penaltyId);
  void clearPenaltiesForEvent(String eventId);
}

class InMemoryPenaltyRepository implements PenaltyRepository {
  final Map<String, List<Penalty>> _byEventId = {};

  @override
  List<Penalty> getPenaltiesForEvent(String eventId) {
    final list = _byEventId[eventId] ?? [];
    return List.unmodifiable(list);
  }

  @override
  void addPenalty(Penalty penalty) {
    final list = _byEventId.putIfAbsent(penalty.eventId, () => []);
    list.add(penalty);
  }

  @override
  void removePenalty(String penaltyId) {
    for (final entry in _byEventId.entries) {
      entry.value.removeWhere((p) => p.id == penaltyId);
    }
  }

  @override
  void clearPenaltiesForEvent(String eventId) {
    _byEventId.remove(eventId);
  }
}
