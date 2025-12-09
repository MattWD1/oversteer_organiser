import '../models/competition.dart';
import '../models/division.dart';

abstract class CompetitionRepository {
  Future<List<Competition>> getCompetitionsForLeague(String leagueId);
  Future<List<Division>> getDivisionsForCompetition(String competitionId);

  /// Move a division into the archive for the given league.
  Future<void> archiveDivision(String leagueId, String divisionId);

  /// All archived divisions for a league (across all its competitions/seasons).
  Future<List<Division>> getArchivedDivisionsForLeague(String leagueId);

  /// Find which competition (season) a division belongs to.
  Future<Competition?> getCompetitionForDivision(String divisionId);
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

  /// leagueId -> set of archived divisionIds
  final Map<String, Set<String>> _archivedDivisionIdsByLeague = {};

  @override
  Future<List<Competition>> getCompetitionsForLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _competitions.where((c) => c.leagueId == leagueId).toList();
  }

  @override
  Future<List<Division>> getDivisionsForCompetition(
      String competitionId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Work out which league this competition belongs to so we can filter out
    // any archived divisions for that league.
    final competition = _competitions.firstWhere(
      (c) => c.id == competitionId,
      orElse: () => throw StateError(
          'Unknown competitionId $competitionId in InMemoryCompetitionRepository'),
    );
    final archivedIds =
        _archivedDivisionIdsByLeague[competition.leagueId] ?? <String>{};

    return _divisions
        .where((d) =>
            d.competitionId == competitionId && !archivedIds.contains(d.id))
        .toList();
  }

  @override
  Future<void> archiveDivision(String leagueId, String divisionId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final archiveSet =
        _archivedDivisionIdsByLeague.putIfAbsent(leagueId, () => <String>{});
    archiveSet.add(divisionId);
  }

  @override
  Future<List<Division>> getArchivedDivisionsForLeague(
      String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final archivedIds = _archivedDivisionIdsByLeague[leagueId] ?? <String>{};
    if (archivedIds.isEmpty) return [];

    final competitionIds = _competitions
        .where((c) => c.leagueId == leagueId)
        .map((c) => c.id)
        .toSet();

    return _divisions
        .where((d) =>
            competitionIds.contains(d.competitionId) &&
            archivedIds.contains(d.id))
        .toList();
  }

  @override
  Future<Competition?> getCompetitionForDivision(String divisionId) async {
    await Future.delayed(const Duration(milliseconds: 50));

    Division? division;
    for (final d in _divisions) {
      if (d.id == divisionId) {
        division = d;
        break;
      }
    }
    if (division == null) return null;

    for (final c in _competitions) {
      if (c.id == division.competitionId) {
        return c;
      }
    }
    return null;
  }
}
