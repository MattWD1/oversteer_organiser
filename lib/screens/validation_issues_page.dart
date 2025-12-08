import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/validation_issue.dart';
import '../repositories/validation_issue_repository.dart';

class ValidationIssuesPage extends StatelessWidget {
  final Event event;
  final ValidationIssueRepository validationIssueRepository;

  const ValidationIssuesPage({
    super.key,
    required this.event,
    required this.validationIssueRepository,
  });

  @override
  Widget build(BuildContext context) {
    final List<ValidationIssue> issues =
        validationIssueRepository.getIssuesForEvent(event.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Validation issues – ${event.name}'),
      ),
      body: issues.isEmpty
          ? const Center(
              child: Text(
                'No validation issues for this event.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final issue = issues[index];

                // crude "severity" based on code – tweak later if you want
                final isError = issue.code.toUpperCase().contains('MISSING') ||
                    issue.code.toUpperCase().contains('DUPLICATE');
                final icon =
                    isError ? Icons.error : Icons.warning_amber_outlined;
                final iconColor = isError ? Colors.red : Colors.orange;

                return Card(
                  child: ListTile(
                    leading: Icon(icon, color: iconColor),
                    title: Text(issue.message),
                    subtitle: Text(
                      [
                        'Code: ${issue.code}',
                        if (issue.driverId != null)
                          'Driver ID: ${issue.driverId}',
                        'Created: ${issue.createdAt}',
                      ].join(' • '),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
