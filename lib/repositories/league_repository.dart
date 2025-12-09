import '../models/league.dart';

abstract class LeagueRepository {
  Future<List<League>> getLeaguesForCurrentUser();
}

class InMemoryLeagueRepository implements LeagueRepository {
  // Simple in-memory data for now
  final List<League> _leagues = [
    League(
      id: 'league1',
      name: 'Fast Racing League',
      organiserName: 'Matt',
      createdAt: DateTime(2025, 1, 10),
    ),
    League(
      id: 'league2',
      name: 'Slow Racing League',
      organiserName: 'Amanda',
      createdAt: DateTime(2025, 2, 5),
    ),
  ];

  @override
  Future<List<League>> getLeaguesForCurrentUser() async {
    // In a real app this would filter by current user.
    await Future.delayed(const Duration(milliseconds: 200));
    return _leagues;
  }
}
