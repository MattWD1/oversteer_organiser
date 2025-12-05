import '../models/competition.dart';

abstract class CompetitionRepository {
  Future<List<Competition>> getCompetitionsForLeague(String leagueId);
}

class InMemoryCompetitionRepository implements CompetitionRepository {
  final List<Competition> _competitions = [
    Competition(
      id: 'comp1',
      leagueId: 'league1',
      name: 'Season 1 – Main Division',
      seasonLabel: 'S1',
    ),
    Competition(
      id: 'comp2',
      leagueId: 'league1',
      name: 'Season 1 – Rookie Division',
      seasonLabel: 'S1R',
    ),
    Competition(
      id: 'comp3',
      leagueId: 'league2',
      name: 'Season 3 – Elite',
      seasonLabel: 'S3',
    ),
  ];

  @override
  Future<List<Competition>> getCompetitionsForLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // fake delay
    return _competitions.where((c) => c.leagueId == leagueId).toList();
  }
}
