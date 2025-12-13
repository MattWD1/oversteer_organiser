// lib/screens/divisions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/penalty.dart';

import '../repositories/league_repository.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';

import '../theme/app_theme.dart';

import 'events_page.dart';
import 'team_profile_page.dart';
import 'league_settings_page.dart';

class DivisionsPage extends StatefulWidget {
  final League league;
  final LeagueRepository leagueRepository;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const DivisionsPage({
    super.key,
    required this.league,
    required this.leagueRepository,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<DivisionsPage> createState() => _DivisionsPageState();
}

class _DivisionsPageState extends State<DivisionsPage> {
  late Future<List<Division>> _futureDivisions;

  // 0 = Divisions list, 1 = Overall Constructors ranking
  int _currentTabIndex = 0;

  // Simple in-memory archive: IDs of divisions that have been archived
  final Set<String> _archivedDivisionIds = {};

  // Local, in-memory divisions created while this page is open
  final List<Division> _localDivisions = [];

  // Dummy competition object – EventsPage still expects a Competition,
  // but doesn’t actually use it for any logic.
  late final Competition _dummyCompetition;

  @override
  void initState() {
    super.initState();
    _futureDivisions =
        widget.competitionRepository.getDivisionsForLeague(widget.league.id);

    _dummyCompetition = Competition(
      id: 'overall_${widget.league.id}',
      leagueId: widget.league.id,
      name: '${widget.league.name} – Season',
      seasonName: null,
    );
  }

  // ---------- Helpers for Constructors ranking ----------

  String _getTeamName(Driver driver) {
    try {
      final dynamic d = driver;
      final value = d.teamName;
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}
    return 'Unknown Team';
  }

  int _pointsForFinish(int position) {
    switch (position) {
      case 1:
        return 25;
      case 2:
        return 18;
      case 3:
        return 15;
      case 4:
        return 12;
      case 5:
        return 10;
      case 6:
        return 8;
      case 7:
        return 6;
      case 8:
        return 4;
      case 9:
        return 2;
      case 10:
        return 1;
      default:
        return 0;
    }
  }

  Future<List<_TeamStanding>> _loadOverallConstructors() async {
    final divisions =
        await widget.competitionRepository.getDivisionsForLeague(widget.league.id);

    if (divisions.isEmpty) {
      return [];
    }

    final Map<String, _TeamStanding> standingsMap = {};

    for (final division in divisions) {
      final List<Event> events =
          await widget.eventRepository.getEventsForDivision(division.id);

      if (events.isEmpty) continue;

      for (final event in events) {
        final List<SessionResult> results =
            widget.sessionResultRepository.getResultsForEvent(event.id);

        if (results.isEmpty) continue;

        final List<Driver> eventDrivers =
            await widget.driverRepository.getDriversForEvent(event.id);
        final Map<String, Driver> driverById = {
          for (final d in eventDrivers) d.id: d,
        };

        final List<Penalty> eventPenalties =
            widget.penaltyRepository.getPenaltiesForEvent(event.id);

        final Map<String, int> timePenaltySecondsByDriver = {};
        final Map<String, int> pointsPenaltyByDriver = {};

        for (final p in eventPenalties) {
          if (p.type == 'Time') {
            timePenaltySecondsByDriver[p.driverId] =
                (timePenaltySecondsByDriver[p.driverId] ?? 0) + p.value;
          } else if (p.type == 'Points') {
            pointsPenaltyByDriver[p.driverId] =
                (pointsPenaltyByDriver[p.driverId] ?? 0) + p.value;
          }
        }

        final List<_EventClassificationEntry> eventEntries = [];

        for (final result in results) {
          final baseTimeMs = result.raceTimeMillis;
          if (baseTimeMs == null) continue;

          final driverId = result.driverId;
          final driver = driverById[driverId];

          final teamName =
              driver != null ? _getTeamName(driver) : 'Unknown Team';

          final timePenSec = timePenaltySecondsByDriver[driverId] ?? 0;
          final adjustedTimeMs = baseTimeMs + timePenSec * 1000;

          eventEntries.add(
            _EventClassificationEntry(
              driverId: driverId,
              driverName: driver?.name ?? 'Unknown driver',
              teamName: teamName,
              baseTimeMs: baseTimeMs,
              adjustedTimeMs: adjustedTimeMs,
            ),
          );
        }

        if (eventEntries.isEmpty) continue;

        // Classify event by adjusted time
        eventEntries.sort(
          (a, b) => a.adjustedTimeMs.compareTo(b.adjustedTimeMs),
        );

        // Award base points per team (via each driver’s result)
        for (var index = 0; index < eventEntries.length; index++) {
          final entry = eventEntries[index];
          final eventPos = index + 1;
          final basePoints = _pointsForFinish(eventPos);

          final standing = standingsMap.putIfAbsent(
            entry.teamName,
            () => _TeamStanding(teamName: entry.teamName),
          );

          standing.basePoints += basePoints;
          if (eventPos == 1) {
            standing.wins += 1;
          }
        }

        // Apply points penalties to teams (mapped from driver → team)
        pointsPenaltyByDriver.forEach((driverId, penaltyPoints) {
          final driver = driverById[driverId];
          final teamName =
              driver != null ? _getTeamName(driver) : 'Unknown Team';

          final standing = standingsMap.putIfAbsent(
            teamName,
            () => _TeamStanding(teamName: teamName),
          );

          standing.penaltyPoints += penaltyPoints;
        });
      }
    }

    final standingsList = standingsMap.values.toList();

    for (final s in standingsList) {
      s.totalPoints = s.basePoints + s.penaltyPoints;
    }

    standingsList.sort((a, b) {
      if (b.totalPoints != a.totalPoints) {
        return b.totalPoints.compareTo(a.totalPoints);
      }
      if (b.wins != a.wins) {
        return b.wins.compareTo(a.wins);
      }
      return a.teamName.compareTo(b.teamName);
    });

    return standingsList;
  }

  // ---------- Create Division ----------

  Future<void> _showCreateDivisionDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Division'),
          content: TextField(
            controller: controller,
            maxLength: 50,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
            ],
            decoration: const InputDecoration(
              labelText: 'Division name',
              hintText: 'e.g. Tier 1, Sunday Elite',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Division name cannot be empty.'),
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

    if (name == null || name.isEmpty) return;

    setState(() {
      final newDivision = Division(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      competitionId: 'local_comp_${widget.league.id}', // or any placeholder
      name: name,
      // If your Division model has more required fields, add them here.
    );


      _localDivisions.add(newDivision);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Division "$name" created.')),
    );
  }

  // ---------- Edit Division ----------

  Future<void> _showEditDivisionDialog(Division division) async {
    final controller = TextEditingController(text: division.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Division Name'),
          content: TextField(
            controller: controller,
            maxLength: 50,
            autofocus: true,
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
            ],
            decoration: const InputDecoration(
              labelText: 'Division name',
              border: OutlineInputBorder(),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Division name cannot be empty.'),
                    ),
                  );
                  return;
                }
                if (text == division.name) {
                  // No change, just close
                  Navigator.of(context).pop<String>(null);
                  return;
                }
                Navigator.of(context).pop<String>(text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.league.themeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    // Update the division name
    await widget.competitionRepository.updateDivisionName(division.id, newName);

    // Refresh the divisions list
    setState(() {
      _futureDivisions = widget.competitionRepository
          .getDivisionsForLeague(widget.league.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Division renamed to "$newName"'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ---------- Social Media ----------

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Widget _buildSocialMediaIcons() {
    final List<Widget> icons = [];

    // TikTok
    if (widget.league.tiktokUrl != null && widget.league.tiktokUrl!.isNotEmpty) {
      icons.add(_buildSocialIcon(
        iconAsset: 'assets/flags/socialmedia/tiktok.svg',
        color: Colors.black,
        url: widget.league.tiktokUrl!,
      ));
    }

    // Twitch
    if (widget.league.twitchUrl != null && widget.league.twitchUrl!.isNotEmpty) {
      icons.add(_buildSocialIcon(
        iconAsset: 'assets/flags/socialmedia/twitch.svg',
        color: const Color(0xFF9146FF),
        url: widget.league.twitchUrl!,
      ));
    }

    // Instagram
    if (widget.league.instagramUrl != null && widget.league.instagramUrl!.isNotEmpty) {
      icons.add(_buildSocialIcon(
        iconAsset: 'assets/flags/socialmedia/instagram.svg',
        color: const Color(0xFFE4405F),
        url: widget.league.instagramUrl!,
      ));
    }

    // YouTube
    if (widget.league.youtubeUrl != null && widget.league.youtubeUrl!.isNotEmpty) {
      icons.add(_buildSocialIcon(
        iconAsset: 'assets/flags/socialmedia/youtube.svg',
        color: const Color(0xFFFF0000),
        url: widget.league.youtubeUrl!,
      ));
    }

    // X (formerly Twitter)
    if (widget.league.twitterUrl != null && widget.league.twitterUrl!.isNotEmpty) {
      icons.add(_buildSocialIcon(
        iconAsset: 'assets/flags/socialmedia/x.svg',
        color: Colors.black,
        url: widget.league.twitterUrl!,
      ));
    }

    // Discord
    if (widget.league.discordUrl != null && widget.league.discordUrl!.isNotEmpty) {
      icons.add(_buildSocialIcon(
        iconAsset: 'assets/flags/socialmedia/discord.svg',
        color: const Color(0xFF5865F2),
        url: widget.league.discordUrl!,
      ));
    }

    if (icons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: icons,
      ),
    );
  }

  Widget _buildSocialIcon({
    required String iconAsset,
    required Color color,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              iconAsset,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Tabs ----------

  Widget _buildDivisionsTab() {
    return FutureBuilder<List<Division>>(
      future: _futureDivisions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading divisions: ${snapshot.error}'),
          );
        }

        final fetchedDivisions = snapshot.data ?? [];

        // Combine divisions from repository with locally created ones
        final allDivisions = <Division>[
          ...fetchedDivisions,
          ..._localDivisions,
        ];

        if (allDivisions.isEmpty) {
          return const Center(
            child: Text('No divisions for this league.'),
          );
        }

        final activeDivisions = allDivisions
            .where((d) => !_archivedDivisionIds.contains(d.id))
            .toList();

        if (activeDivisions.isEmpty) {
          return Column(
            children: [
              _buildSocialMediaIcons(),
              const Expanded(
                child: Center(
                  child: Text(
                    'No active divisions. Archived divisions are in the archive.',
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildSocialMediaIcons(),
            Expanded(
              child: ListView.builder(
                itemCount: activeDivisions.length,
                itemBuilder: (context, index) {
                  final division = activeDivisions[index];

            return Dismissible(
              key: Key(division.id),
              direction: DismissDirection.horizontal,
              confirmDismiss: (direction) async {
                // Swipe left = edit, swipe right = delete
                if (direction == DismissDirection.endToStart) {
                  // Edit division name
                  await _showEditDivisionDialog(division);
                  return false; // Don't dismiss, just show edit dialog
                } else {
                  // Delete division (swipe right)
                  // Generate a random 6-digit code
                  final code = (100000 +
                      (999999 - 100000) *
                      (DateTime.now().millisecondsSinceEpoch % 1000) / 1000
                  ).toInt().toString();

                  final controller = TextEditingController();

                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Division'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are about to permanently delete "${division.name}".\n\n'
                            'This will delete all events and data associated with this division.\n\n'
                            'To confirm, please enter this code:',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.league.themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: widget.league.themeColor),
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
                                SnackBar(
                                  content: const Text('Incorrect code. Please try again.'),
                                  backgroundColor: widget.league.themeColor,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.league.themeColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  return confirmed ?? false;
                }
              },
              onDismissed: (direction) async {
                await widget.competitionRepository.deleteDivision(division.id);
                setState(() {
                  _futureDivisions = widget.competitionRepository
                      .getDivisionsForLeague(widget.league.id);
                });
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${division.name}" has been deleted'),
                  ),
                );
              },
              background: Container(
                color: widget.league.themeColor,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              secondaryBackground: Container(
                color: Colors.blue,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              child: ListTile(
                title: Text(division.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventsPage(
                        league: widget.league,
                        competition: _dummyCompetition,
                        division: division,
                        competitionRepository: widget.competitionRepository,
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
                onLongPress: () async {
                final shouldArchive = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Archive division'),
                        content: Text(
                          'Archive "${division.name}"? It will be removed from the active list but still visible in the archive.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Archive'),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (shouldArchive) {
                  setState(() {
                    _archivedDivisionIds.add(division.id);
                  });

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Archived ${division.name}.')),
                  );
                }
              },
              ),
            );
          },
        ),
      ),
    ],
        );
      },
    );
  }

  Widget _buildRankingTab() {
    return FutureBuilder<List<_TeamStanding>>(
      future: _loadOverallConstructors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading rankings: ${snapshot.error}'),
          );
        }

        final standings = snapshot.data ?? [];

        if (standings.isEmpty) {
          return const Center(
            child: Text('No classified results yet for this league.'),
          );
        }

        return ListView.builder(
          itemCount: standings.length,
          itemBuilder: (context, index) {
            final standing = standings[index];
            final position = index + 1;

            final base = standing.basePoints;
            final pen = standing.penaltyPoints;
            final total = standing.totalPoints;

            final subtitle =
                'Points: $total (Base $base, Penalties $pen) • Wins: ${standing.wins}';

            return ListTile(
              leading: CircleAvatar(
                child: Text(position.toString()),
              ),
              title: Text(standing.teamName),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TeamProfilePage(
                      teamName: standing.teamName,
                      league: widget.league,
                      competitionRepository: widget.competitionRepository,
                      eventRepository: widget.eventRepository,
                      driverRepository: widget.driverRepository,
                      sessionResultRepository: widget.sessionResultRepository,
                      penaltyRepository: widget.penaltyRepository,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showArchiveDialog() async {
    final divisions =
        await widget.competitionRepository.getDivisionsForLeague(widget.league.id);

    final allDivisions = <Division>[
      ...divisions,
      ..._localDivisions,
    ];

    final archivedDivisions = allDivisions
        .where((d) => _archivedDivisionIds.contains(d.id))
        .toList();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archived divisions'),
          content: SizedBox(
            width: double.maxFinite,
            child: archivedDivisions.isEmpty
                ? const Text('No archived divisions yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: archivedDivisions.length,
                    itemBuilder: (context, index) {
                      final d = archivedDivisions[index];
                      return ListTile(
                        title: Text(d.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EventsPage(
                                league: widget.league,
                                competition: _dummyCompetition,
                                division: d,
                                competitionRepository: widget.competitionRepository,
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
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_currentTabIndex) {
      case 0:
        body = _buildDivisionsTab();
        break;
      case 1:
      default:
        body = _buildRankingTab();
        break;
    }

    return AppTheme(
      primaryColor: widget.league.themeColor,
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.league.name),
        actions: [
          IconButton(
            tooltip: 'League Settings',
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final colorChanged = await navigator.push<bool>(
                MaterialPageRoute(
                  builder: (_) => LeagueSettingsPage(
                    league: widget.league,
                    competitionRepository: widget.competitionRepository,
                    leagueRepository: widget.leagueRepository,
                  ),
                ),
              );

              // If color was changed, pop this page and signal to LeaguesPage
              // that it needs to refresh the league data
              if (colorChanged == true && mounted) {
                navigator.pop(true);
              }
            },
          ),
          IconButton(
            tooltip: 'View archive',
            icon: const Icon(Icons.archive_outlined),
            onPressed: _showArchiveDialog,
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Divisions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Ranking',
          ),
        ],
      ),
      // Only show + when on Divisions tab
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: _showCreateDivisionDialog,
              tooltip: 'Add division',
              backgroundColor: HSLColor.fromColor(widget.league.themeColor)
                  .withLightness(0.65)
                  .toColor(),
              child: const Icon(Icons.add),
            )
          : null,
      ),
    );
  }
}

// ---------- helper classes for overall constructors ----------

class _TeamStanding {
  final String teamName;
  int basePoints;
  int penaltyPoints;
  int totalPoints;
  int wins;

  _TeamStanding({
    required this.teamName,
  })  : basePoints = 0,
        penaltyPoints = 0,
        totalPoints = 0,
        wins = 0;
}

class _EventClassificationEntry {
  final String driverId;
  final String driverName;
  final String teamName;
  final int baseTimeMs;
  final int adjustedTimeMs;

  _EventClassificationEntry({
    required this.driverId,
    required this.driverName,
    required this.teamName,
    required this.baseTimeMs,
    required this.adjustedTimeMs,
  });
}
