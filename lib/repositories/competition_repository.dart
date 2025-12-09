// lib/repositories/competition_repository.dart

import '../models/competition.dart';
import '../models/division.dart';

abstract class CompetitionRepository {
  Future<List<Competition>> getCompetitionsForLeague(String leagueId);

  /// Active divisions for a given competition (non-archived only).
  Future<List<Division>> getDivisionsForCompetition(String competitionId);

  /// Active divisions for a whole league (non-archived only).
  Future<List<Division>> getDivisionsForLeague(String leagueId);

  /// Archived divisions for a whole league.
  Future<List<Division>> getArchivedDivisionsForLeague(String leagueId);

  /// Look up the competition a division originally belongs to.
  Future<Competition?> getCompetitionForDivision(String divisionId);

  /// Mark a division as archived.
  Future<void> archiveDivision(String divisionId);

  /// Bring a division back from archive.
  Future<void> unarchiveDivision(String divisionId);
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

  /// IDs of divisions that have been archived.
  final Set<String> _archivedDivisionIds = {};

  @override
  Future<List<Competition>> getCompetitionsForLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _competitions.where((c) => c.leagueId == leagueId).toList();
  }

  @override
  Future<List<Division>> getDivisionsForCompetition(
      String competitionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _divisions
        .where(
          (d) =>
              d.competitionId == competitionId &&
              !_archivedDivisionIds.contains(d.id),
        )
        .toList();
  }

  @override
  Future<List<Division>> getDivisionsForLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final leagueCompetitionIds = _competitions
        .where((c) => c.leagueId == leagueId)
        .map((c) => c.id)
        .toSet();

    return _divisions
        .where(
          (d) =>
              leagueCompetitionIds.contains(d.competitionId) &&
              !_archivedDivisionIds.contains(d.id),
        )
        .toList();
  }

  @override
  Future<List<Division>> getArchivedDivisionsForLeague(
      String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final leagueCompetitionIds = _competitions
        .where((c) => c.leagueId == leagueId)
        .map((c) => c.id)
        .toSet();

    return _divisions
        .where(
          (d) =>
              leagueCompetitionIds.contains(d.competitionId) &&
              _archivedDivisionIds.contains(d.id),
        )
        .toList();
  }

  @override
  Future<Competition?> getCompetitionForDivision(String divisionId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Find the division manually so we can handle "not found" without null
    Division? division;
    for (final d in _divisions) {
      if (d.id == divisionId) {
        division = d;
        break;
      }
    }
    if (division == null) return null;

    // Now find the competition for that division
    Competition? competition;
    for (final c in _competitions) {
      if (c.id == division.competitionId) {
        competition = c;
        break;
      }
    }
    return competition;
  }

  @override
  Future<void> archiveDivision(String divisionId) async {
    _archivedDivisionIds.add(divisionId);
  }

  @override
  Future<void> unarchiveDivision(String divisionId) async {
    _archivedDivisionIds.remove(divisionId);
  }
}
