import '../models/session_result.dart';

class SessionResultRepository {
  // key: eventId, value: list of results for that event
  final Map<String, List<SessionResult>> _resultsByEvent = {};

  List<SessionResult> getResultsForEvent(String eventId) {
    final existing = _resultsByEvent[eventId] ?? [];
    return existing
        .map(
          (r) => SessionResult(
            eventId: r.eventId,
            driverId: r.driverId,
            gridPosition: r.gridPosition,
            finishPosition: r.finishPosition,
          ),
        )
        .toList();
  }

  void saveResultsForEvent(String eventId, List<SessionResult> results) {
    _resultsByEvent[eventId] = results
        .map(
          (r) => SessionResult(
            eventId: r.eventId,
            driverId: r.driverId,
            gridPosition: r.gridPosition,
            finishPosition: r.finishPosition,
          ),
        )
        .toList();
  }
}
