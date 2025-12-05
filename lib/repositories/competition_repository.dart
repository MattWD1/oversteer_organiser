import '../models/competition.dart';
import '../models/division.dart';

abstract class CompetitionRepository {
  Future<List<Competition>> getCompetitionsForLeague(String leagueId);
  Future<List<Division>> getDivisionsForCompetition(String competitionId);
}

class InMemoryCompetitionRepository implements CompetitionRepository {
  final List<Competition> _competitions = const [
    Competition(
      id: 'comp1',
      leagueId: 'league1',
      name: 'Season 1',
      seasonName: '2025',
    ),
    Competition(
      id: 'comp2',
      leagueId: 'league2',
      name: 'Season 1',
      seasonName: '2025',
    ),
  ];

  final List<Division> _divisions = const [
    Division(id: 'div1', competitionId: 'comp1', name: 'Tier 1'),
    Division(id: 'div2', competitionId: 'comp1', name: 'Tier 2'),
    Division(id: 'div3', competitionId: 'comp2', name: 'Single Tier'),
  ];

  @override
  Future<List<Competition>> getCompetitionsForLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _competitions.where((c) => c.leagueId == leagueId).toList();
  }

  @override
  Future<List<Division>> getDivisionsForCompetition(
      String competitionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _divisions.where((d) => d.competitionId == competitionId).toList();
  }
}
