// lib/repositories/session_result_repository.dart

import '../models/session_result.dart';

class SessionResultRepository {
  final Map<String, List<SessionResult>> _resultsByEventId = {};

  /// Returns a copy of the results list for the given eventId.
  List<SessionResult> getResultsForEvent(String eventId) {
    final list = _resultsByEventId[eventId];
    if (list == null) return [];
    return List<SessionResult>.from(list);
  }

  /// Saves the full set of results for a given event.
  void saveResultsForEvent(String eventId, List<SessionResult> results) {
    _resultsByEventId[eventId] = List<SessionResult>.from(results);
  }

  /// Clears any stored results for the event.
  void clearResultsForEvent(String eventId) {
    _resultsByEventId.remove(eventId);
  }
}
