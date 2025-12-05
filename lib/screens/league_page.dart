import 'package:flutter/material.dart';
import '../models/league.dart';
import '../repositories/league_repository.dart';

class LeaguesPage extends StatefulWidget {
  final LeagueRepository repository;

  const LeaguesPage({super.key, required this.repository});

  @override
  State<LeaguesPage> createState() => _LeaguesPageState();
}

class _LeaguesPageState extends State<LeaguesPage> {
  late Future<List<League>> _futureLeagues;

  @override
  void initState() {
    super.initState();
    _futureLeagues = widget.repository.getLeaguesForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leagues'),
      ),
      body: FutureBuilder<List<League>>(
        future: _futureLeagues,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leagues: ${snapshot.error}'),
            );
          }
          final leagues = snapshot.data ?? [];
          if (leagues.isEmpty) {
            return const Center(child: Text('No leagues yet.'));
          }

          return ListView.builder(
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              return ListTile(
                title: Text(league.name),
                subtitle: Text('Organiser: ${league.organiserName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // we'll wire this to competitions later
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped ${league.name}')),
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
