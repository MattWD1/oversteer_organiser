import '../models/league.dart';

abstract class LeagueRepository {
  Future<List<League>> getLeaguesForCurrentUser();
}

class InMemoryLeagueRepository implements LeagueRepository {
  final List<League> _leagues = [
    League(
      id: 'league1',
      name: 'Monday Night F1',
      organiserName: 'Matt',
      code: 'MON123',
    ),
    League(
      id: 'league2',
      name: 'EU Tier 1',
      organiserName: 'SimRacing Hub',
      code: 'EUT1',
    ),
  ];

  @override
  Future<List<League>> getLeaguesForCurrentUser() async {
    // later: filter by actual user; for now just return everything
    await Future.delayed(const Duration(milliseconds: 200)); // tiny fake delay
    return _leagues;
  }
}
