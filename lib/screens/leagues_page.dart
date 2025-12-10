import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/league.dart';
import '../repositories/league_repository.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';
import 'divisions_page.dart';

enum LeagueSortOption {
  nameAsc,
  nameDesc,
  dateCreatedNewest,
}

class LeaguesPage extends StatefulWidget {
  final LeagueRepository repository;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const LeaguesPage({
    super.key,
    required this.repository,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<LeaguesPage> createState() => _LeaguesPageState();
}

class _LeaguesPageState extends State<LeaguesPage> {
  late Future<List<League>> _futureLeagues;
  LeagueSortOption _sortOption = LeagueSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _futureLeagues = widget.repository.getLeaguesForCurrentUser();
  }

  Future<void> _refreshLeagues() async {
    setState(() {
      _futureLeagues = widget.repository.getLeaguesForCurrentUser();
    });
  }

  String _sortLabel(LeagueSortOption option) {
    switch (option) {
      case LeagueSortOption.nameAsc:
        return 'Name (A–Z)';
      case LeagueSortOption.nameDesc:
        return 'Name (Z–A)';
      case LeagueSortOption.dateCreatedNewest:
        return 'Date Created (Newest)';
    }
  }

  List<League> _sortedLeagues(List<League> source) {
    final leagues = List<League>.from(source);

    leagues.sort((a, b) {
      switch (_sortOption) {
        case LeagueSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case LeagueSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case LeagueSortOption.dateCreatedNewest:
          // Newest first
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return leagues;
  }

  void _showAddLeagueOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create a league'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCreateLeagueDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Join an existing league'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showJoinLeagueDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateLeagueDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create League'),
          content: TextField(
            controller: controller,
            maxLength: 50,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
            ],
            decoration: const InputDecoration(
              labelText: 'League name',
              hintText: 'Enter a league name (max 50 characters)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop<String>(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  // basic inline validation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('League name cannot be empty.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop<String>(text);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final league = await widget.repository.createLeague(name);
    if (!mounted) return;

    await _refreshLeagues();

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'League "${league.name}" created. Join code: ${league.joinCode}',
        ),
      ),
    );
  }

  Future<void> _showJoinLeagueDialog() async {
    final controller = TextEditingController();

    final joinCode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join League'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Join code',
              hintText: 'Enter the league join code',
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop<String>(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Join code cannot be empty.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop<String>(text);
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (joinCode == null || joinCode.isEmpty) {
      return;
    }

    final league = await widget.repository.joinLeague(joinCode);
    if (!mounted) return;

    if (league == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No league found for that join code.'),
        ),
      );
      return;
    }

    await _refreshLeagues();

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined league "${league.name}".'),
      ),
    );
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading leagues: ${snapshot.error}'),
            );
          }

          final originalLeagues = snapshot.data ?? [];

          if (originalLeagues.isEmpty) {
            return const Center(
              child: Text('No leagues yet. Tap + to get started.'),
            );
          }

          final leagues = _sortedLeagues(originalLeagues);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sort by',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    PopupMenuButton<LeagueSortOption>(
                      initialValue: _sortOption,
                      onSelected: (value) {
                        setState(() {
                          _sortOption = value;
                        });
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: LeagueSortOption.nameAsc,
                          child: Text('Name (A–Z)'),
                        ),
                        PopupMenuItem(
                          value: LeagueSortOption.nameDesc,
                          child: Text('Name (Z–A)'),
                        ),
                        PopupMenuItem(
                          value: LeagueSortOption.dateCreatedNewest,
                          child: Text('Date Created (Newest)'),
                        ),
                      ],
                      child: Row(
                        children: [
                          Text(
                            _sortLabel(_sortOption),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: leagues.length,
                  itemBuilder: (context, index) {
                    final league = leagues[index];

                    return Dismissible(
                      key: Key(league.id),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (direction) async {
                        // Generate a random 6-digit code
                        final code = (100000 +
                            (999999 - 100000) *
                            (DateTime.now().millisecondsSinceEpoch % 1000) / 1000
                        ).toInt().toString();

                        final controller = TextEditingController();

                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete League'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You are about to permanently delete "${league.name}".\n\n'
                                  'This will delete ALL divisions, events, and data associated with this league.\n\n'
                                  'To confirm, please enter this code:',
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Text(
                                    code,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Enter code',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (controller.text == code) {
                                    Navigator.of(context).pop(true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Incorrect code. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        return confirmed ?? false;
                      },
                      onDismissed: (direction) async {
                        await widget.repository.deleteLeague(league.id);
                        setState(() {
                          _futureLeagues = widget.repository.getLeaguesForCurrentUser();
                        });
                        if (!mounted) return;
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${league.name}" has been deleted'),
                          ),
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      child: ListTile(
                        title: Text(league.name),
                        subtitle: Text('Organiser: ${league.organiserName}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DivisionsPage(
                                league: league,
                                competitionRepository:
                                    widget.competitionRepository,
                                eventRepository: widget.eventRepository,
                                driverRepository: widget.driverRepository,
                                sessionResultRepository:
                                    widget.sessionResultRepository,
                                validationIssueRepository:
                                    widget.validationIssueRepository,
                                penaltyRepository: widget.penaltyRepository,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLeagueOptions,
        tooltip: 'Add league',
        child: const Icon(Icons.add),
      ),
    );
  }
}
