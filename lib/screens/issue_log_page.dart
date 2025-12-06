import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/validation_issue.dart';
import '../repositories/validation_issue_repository.dart';

class IssueLogPage extends StatelessWidget {
  final Event event;
  final ValidationIssueRepository validationIssueRepository;

  const IssueLogPage({
    super.key,
    required this.event,
    required this.validationIssueRepository,
  });

  @override
  Widget build(BuildContext context) {
    final issues = validationIssueRepository.getIssuesForEvent(event.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Issue Log – ${event.name}'),
      ),
      body: issues.isEmpty
          ? const Center(
              child: Text('No validation issues for this event.'),
            )
          : ListView.builder(
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final ValidationIssue issue = issues[index];

                return ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(issue.message),
                  subtitle: Text(
                    '${issue.code} • '
                    '${issue.createdAt.day}/${issue.createdAt.month}/${issue.createdAt.year} '
                    '${issue.createdAt.hour.toString().padLeft(2, '0')}:'
                    '${issue.createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                );
              },
            ),
    );
  }
}
