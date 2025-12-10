import 'dart:math';

import '../models/league.dart';

abstract class LeagueRepository {
  Future<List<League>> getLeaguesForCurrentUser();

  /// Create a new league with the given name and add it to the current user.
  Future<League> createLeague(String name);

  /// Join an existing league by join code. Returns null if not found.
  Future<League?> joinLeague(String joinCode);

  /// Permanently delete a league.
  Future<void> deleteLeague(String leagueId);
}

class InMemoryLeagueRepository implements LeagueRepository {
  final List<League> _allLeagues = [
    League(
      id: 'league1',
      name: 'F1 Sunday League',
      organiserName: 'Matt',
      createdAt: DateTime(2025, 1, 10),
      joinCode: 'SUNF1A',
    ),
    League(
      id: 'league2',
      name: 'Midweek Sprint League',
      organiserName: 'Alex',
      createdAt: DateTime(2025, 2, 5),
      joinCode: 'MIDSPT',
    ),
  ];

  // Which leagues the "current user" belongs to.
  final Set<String> _userLeagueIds = {'league1', 'league2'};

  final Random _random = Random();
  int _nextLeagueNumber = 3;

  String _generateLeagueId() {
    final id = 'league$_nextLeagueNumber';
    _nextLeagueNumber++;
    return id;
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Future<List<League>> getLeaguesForCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _allLeagues
        .where((league) => _userLeagueIds.contains(league.id))
        .toList();
  }

  @override
  Future<League> createLeague(String name) async {
    final league = League(
      id: _generateLeagueId(),
      name: name,
      organiserName: 'You', // placeholder until we plug in real user data
      createdAt: DateTime.now(),
      joinCode: _generateJoinCode(),
    );

    _allLeagues.add(league);
    _userLeagueIds.add(league.id);

    await Future.delayed(const Duration(milliseconds: 200));
    return league;
  }

  @override
  Future<League?> joinLeague(String joinCode) async {
    await Future.delayed(const Duration(milliseconds: 200));

    League? found;
    try {
      found = _allLeagues.firstWhere(
        (l) => l.joinCode.toUpperCase() == joinCode.toUpperCase().trim(),
      );
    } catch (_) {
      found = null;
    }

    if (found != null) {
      _userLeagueIds.add(found.id);
    }

    return found;
  }

  @override
  Future<void> deleteLeague(String leagueId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _allLeagues.removeWhere((l) => l.id == leagueId);
    _userLeagueIds.remove(leagueId);
  }
}
