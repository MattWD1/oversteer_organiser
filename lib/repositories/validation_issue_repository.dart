import '../models/validation_issue.dart';

class ValidationIssueRepository {
  // key: eventId, value: list of issues for that event
  final Map<String, List<ValidationIssue>> _issuesByEvent = {};

  List<ValidationIssue> getIssuesForEvent(String eventId) {
    final existing = _issuesByEvent[eventId] ?? [];
    return existing
        .map(
          (i) => ValidationIssue(
            id: i.id,
            eventId: i.eventId,
            driverId: i.driverId,
            code: i.code,
            message: i.message,
            createdAt: i.createdAt,
            isResolved: i.isResolved,
          ),
        )
        .toList();
  }

  /// Replace all issues for the given event (e.g. after running validation again)
  void replaceIssuesForEvent(String eventId, List<ValidationIssue> issues) {
    _issuesByEvent[eventId] = issues
        .map(
          (i) => ValidationIssue(
            id: i.id,
            eventId: i.eventId,
            driverId: i.driverId,
            code: i.code,
            message: i.message,
            createdAt: i.createdAt,
            isResolved: i.isResolved,
          ),
        )
        .toList();
  }

  /// Clear issues for an event (e.g. if everything is valid)
  void clearIssuesForEvent(String eventId) {
    _issuesByEvent.remove(eventId);
  }
}
