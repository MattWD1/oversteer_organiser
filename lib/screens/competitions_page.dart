import 'package:flutter/material.dart';
import '../models/league.dart';
import '../models/competition.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import 'division_page.dart';

class CompetitionsPage extends StatefulWidget {
  final League league;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;

  const CompetitionsPage({
    super.key,
    required this.league,
    required this.competitionRepository,
    required this.eventRepository,
  });

  @override
  State<CompetitionsPage> createState() => _CompetitionsPageState();
}

class _CompetitionsPageState extends State<CompetitionsPage> {
  late Future<List<Competition>> _futureCompetitions;

  @override
  void initState() {
    super.initState();
    _futureCompetitions =
        widget.competitionRepository.getCompetitionsForLeague(widget.league.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league.name),
      ),
      body: FutureBuilder<List<Competition>>(
        future: _futureCompetitions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading competitions: ${snapshot.error}'),
            );
          }

          final competitions = snapshot.data ?? [];
          if (competitions.isEmpty) {
            return const Center(
              child: Text('No competitions for this league yet.'),
            );
          }

          return ListView.builder(
            itemCount: competitions.length,
            itemBuilder: (context, index) {
              final comp = competitions[index];

              return ListTile(
                title: Text(comp.name),
                subtitle: Text(comp.seasonLabel),
                trailing: const Icon(Icons.sports_motorsports),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DivisionPage(
                        competition: comp,
                        eventRepository: widget.eventRepository,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
