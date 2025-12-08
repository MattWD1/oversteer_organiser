// lib/repositories/session_result_repository.dart

import '../models/session_result.dart';

class SessionResultRepository {
  // key: eventId, value: list of results for that event
  final Map<String, List<SessionResult>> _resultsByEvent = {};

  List<SessionResult> getResultsForEvent(String eventId) {
    final existing = _resultsByEvent[eventId] ?? [];
    // Return defensive copies
    return existing
        .map(
          (r) => SessionResult(
            driverId: r.driverId,
            gridPosition: r.gridPosition,
            finishPosition: r.finishPosition,
            raceTimeMillis: r.raceTimeMillis,
            hasFastestLap: r.hasFastestLap,
            fastestLapMillis: r.fastestLapMillis,
            poleLapMillis: r.poleLapMillis,
          ),
        )
        .toList();
  }

  /// Replace all results for the given event (e.g. after saving from SessionPage)
  void saveResultsForEvent(String eventId, List<SessionResult> results) {
    _resultsByEvent[eventId] = results
        .map(
          (r) => SessionResult(
            driverId: r.driverId,
            gridPosition: r.gridPosition,
            finishPosition: r.finishPosition,
            raceTimeMillis: r.raceTimeMillis,
            hasFastestLap: r.hasFastestLap,
            fastestLapMillis: r.fastestLapMillis,
            poleLapMillis: r.poleLapMillis,
          ),
        )
        .toList();
  }

  /// Optional helper if you ever want to clear results for an event
  void clearResultsForEvent(String eventId) {
    _resultsByEvent.remove(eventId);
  }
}
