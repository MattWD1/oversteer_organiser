import '../models/league.dart';

abstract class LeagueRepository {
  Future<List<League>> getLeaguesForCurrentUser();
}

class InMemoryLeagueRepository implements LeagueRepository {
  final List<League> _leagues = const [
    League(id: 'league1', name: 'F1 Sunday League', organiserName: 'Matt'),
    League(id: 'league2', name: 'Midweek Sprint League', organiserName: 'Alex'),
  ];

  @override
  Future<List<League>> getLeaguesForCurrentUser() async {
    // In a real app this would filter by current user.
    await Future.delayed(const Duration(milliseconds: 200));
    return _leagues;
  }
}
