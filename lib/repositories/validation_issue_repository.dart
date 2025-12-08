import '../models/validation_issue.dart';

class ValidationIssueRepository {
  // key: eventId, value: list of issues for that event
  final Map<String, List<ValidationIssue>> _issuesByEvent = {};

  List<ValidationIssue> getIssuesForEvent(String eventId) {
    final existing = _issuesByEvent[eventId] ?? [];
    // return defensive copies so callers can't mutate internal state
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

  /// True if there are any issues (resolved or not) for this event
  bool hasIssuesForEvent(String eventId) {
    final issues = _issuesByEvent[eventId];
    return issues != null && issues.isNotEmpty;
  }

  /// Count only unresolved issues for this event
  int countOpenIssuesForEvent(String eventId) {
    final issues = _issuesByEvent[eventId] ?? [];
    return issues.where((i) => !i.isResolved).length;
  }

  /// Mark a specific issue as resolved for an event
  void markIssueResolved(String eventId, String issueId) {
    final issues = _issuesByEvent[eventId];
    if (issues == null) return;

    final index = issues.indexWhere((i) => i.id == issueId);
    if (index == -1) return;

    final existing = issues[index];
    issues[index] = existing.copyWith(isResolved: true);
  }
}
