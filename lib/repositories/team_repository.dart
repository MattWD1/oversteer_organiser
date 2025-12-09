import 'dart:async';

import '../models/team.dart';

abstract class TeamRepository {
  /// All teams registered in a league.
  Future<List<Team>> getTeamsForLeague(String leagueId);

  /// Look up a team by its ID.
  Future<Team?> getTeamById(String teamId);
}

class InMemoryTeamRepository implements TeamRepository {
  // Example teams. Adjust leagueIds / names to match your sample data.
  final List<Team> _teams = const [
    Team(
      id: 'team_mercedes',
      leagueId: 'league1',
      name: 'Mercedes',
    ),
    Team(
      id: 'team_redbull',
      leagueId: 'league1',
      name: 'Red Bull Racing',
    ),
    Team(
      id: 'team_ferrari',
      leagueId: 'league1',
      name: 'Scuderia Ferrari',
    ),
    Team(
      id: 'team_mclaren',
      leagueId: 'league1',
      name: 'McLaren',
    ),
    // You can add separate teams for league2 if you want different grids.
  ];

  @override
  Future<List<Team>> getTeamsForLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _teams.where((t) => t.leagueId == leagueId).toList();
  }

  @override
  Future<Team?> getTeamById(String teamId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    for (final t in _teams) {
      if (t.id == teamId) return t;
    }
    return null;
  }
}
