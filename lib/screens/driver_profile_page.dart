// lib/screens/driver_profile_page.dart

import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/session_result.dart';
import '../models/penalty.dart';
import '../repositories/event_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/penalty_repository.dart';

class DriverProfilePage extends StatefulWidget {
  final Driver driver;
  final Division division;
  final EventRepository eventRepository;
  final SessionResultRepository sessionResultRepository;
  final PenaltyRepository penaltyRepository;

  const DriverProfilePage({
    super.key,
    required this.driver,
    required this.division,
    required this.eventRepository,
    required this.sessionResultRepository,
    required this.penaltyRepository,
  });

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  late String _name;
  int? _number;
  String? _nationality;

  bool _statsLoading = true;
  String? _statsError;

  int _racesEntered = 0;
  int _wins = 0;
  int _podiums = 0;
  int _polePositions = 0;
  int _fastestLaps = 0;
  int _totalPoints = 0;
  int _totalPenaltyPoints = 0;
  int _totalGainedPositions = 0;
  double _averagePosition = 0;
  double _pointsPerRace = 0;

  final List<_RaceStat> _raceStats = [];

  // Simple list of countries, alphabetically sorted.
  static const List<String> _allCountries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo (Congo-Brazzaville)',
    'Costa Rica',
    'Côte d\'Ivoire',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Democratic Republic of the Congo',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  @override
  void initState() {
    super.initState();

    _name = widget.driver.name;

    // Try to read number & nationality safely from the Driver model.
    try {
      final dynamic d = widget.driver;

      final dynamic maybeNumber = d.number;
      if (maybeNumber is int) {
        _number = maybeNumber;
      } else if (maybeNumber is String) {
        _number = int.tryParse(maybeNumber);
      }

      final dynamic maybeNationality = d.nationality;
      if (maybeNationality is String && maybeNationality.isNotEmpty) {
        _nationality = maybeNationality;
      }
    } catch (_) {
      // If fields don't exist on the model, we just leave them null.
    }

    _loadSeasonStats();
  }

  Future<void> _loadSeasonStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
      _racesEntered = 0;
      _wins = 0;
      _podiums = 0;
      _polePositions = 0;
      _fastestLaps = 0;
      _totalPoints = 0;
      _totalPenaltyPoints = 0;
      _totalGainedPositions = 0;
      _averagePosition = 0;
      _pointsPerRace = 0;
      _raceStats.clear();
    });

    try {
      final List<Event> events =
          await widget.eventRepository.getEventsForDivision(widget.division.id);

      if (events.isEmpty) {
        setState(() {
          _statsLoading = false;
        });
        return;
      }

      int sumPositions = 0;
      int sumPenaltyPoints = 0;
      int sumGainedPositions = 0;

      for (final event in events) {
        final List<SessionResult> results =
            widget.sessionResultRepository.getResultsForEvent(event.id);

        if (results.isEmpty) {
          continue;
        }

        // Penalties for this event
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

        // Build classification for this event (adjusted times)
        final List<_EventEntry> entries = [];

        for (final result in results) {
          final baseTimeMs = result.raceTimeMillis;
          if (baseTimeMs == null) {
            continue;
          }

          final driverId = result.driverId;
          final timePenSec = timePenaltySecondsByDriver[driverId] ?? 0;
          final adjustedTimeMs = baseTimeMs + timePenSec * 1000;

          entries.add(
            _EventEntry(
              driverId: driverId,
              baseTimeMs: baseTimeMs,
              adjustedTimeMs: adjustedTimeMs,
            ),
          );
        }

        if (entries.isEmpty) {
          continue;
        }

        // Sort by adjusted time
        entries.sort(
          (a, b) => a.adjustedTimeMs.compareTo(b.adjustedTimeMs),
        );

        // Where did this driver finish?
        final int index = entries.indexWhere(
          (e) => e.driverId == widget.driver.id,
        );

        // Get this driver's raw result (grid/finish/fastest lap flags etc.)
        SessionResult? driverResult;
        for (final r in results) {
          if (r.driverId == widget.driver.id) {
            driverResult = r;
            break;
          }
        }

        if (driverResult == null) {
          // No classified result for this driver in this event
          continue;
        }

        // Fastest lap?
        if (driverResult.hasFastestLap) {
          _fastestLaps += 1;
        }

        // Pole position? (based on gridPosition == 1)
        if (driverResult.gridPosition == 1) {
          _polePositions += 1;
        }

        if (index == -1) {
          // No classified finishing position (e.g. no race time)
          continue;
        }

        final position = index + 1;
        final basePoints = _pointsForFinish(position);
        final penaltyPoints = pointsPenaltyByDriver[widget.driver.id] ?? 0;
        final totalPointsForRace = basePoints + penaltyPoints;

        _racesEntered += 1;
        _totalPoints += totalPointsForRace;

        sumPositions += position;
        sumPenaltyPoints += penaltyPoints;

        // Gained positions (only count when they moved forward)
        final int? grid = driverResult.gridPosition;
        if (grid != null && position < grid) {
          sumGainedPositions += (grid - position);
        }

        if (position == 1) {
          _wins += 1;
        }
        if (position <= 3) {
          _podiums += 1;
        }

        _raceStats.add(
          _RaceStat(
            eventName: event.name,
            position: position,
            basePoints: basePoints,
            penaltyPoints: penaltyPoints,
            totalPoints: totalPointsForRace,
          ),
        );
      }

      if (_racesEntered > 0) {
        _averagePosition = sumPositions / _racesEntered;
        _pointsPerRace = _totalPoints / _racesEntered;
      } else {
        _averagePosition = 0;
        _pointsPerRace = 0;
      }

      _totalPenaltyPoints = sumPenaltyPoints;
      _totalGainedPositions = sumGainedPositions;

      setState(() {
        _statsLoading = false;
      });
    } catch (e) {
      setState(() {
        _statsLoading = false;
        _statsError = 'Error loading season stats: $e';
      });
    }
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

  void _openEditSheet() {
    final numberController = TextEditingController(
      text: _number != null ? _number.toString() : '',
    );

    String searchTerm = '';
    String? selectedNationality = _nationality;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final lowerSearch = searchTerm.toLowerCase();
            final List<String> filteredCountries = _allCountries
                .where(
                  (c) => c.toLowerCase().contains(lowerSearch),
                )
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit driver details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Driver number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Driver nationality',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search country',
                      hintText: 'Start typing to filter countries...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchTerm = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: filteredCountries.isEmpty
                        ? const Center(
                            child: Text(
                              'No countries match your search.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCountries.length,
                            itemBuilder: (context, index) {
                              final country = filteredCountries[index];
                              final bool isSelected =
                                  country == selectedNationality;

                              return ListTile(
                                title: Text(country),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  setModalState(() {
                                    selectedNationality = country;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        final numberText = numberController.text.trim();
                        final newNumber = numberText.isEmpty
                            ? null
                            : int.tryParse(numberText);

                        setState(() {
                          _number = newNumber;
                          _nationality = selectedNationality;
                        });

                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Driver profile updated (local only).'),
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberText = _number != null ? _number.toString() : 'Not set';
    final nationalityText = _nationality ?? 'Not set';

    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          IconButton(
            tooltip: 'Edit driver details',
            icon: const Icon(Icons.edit),
            onPressed: _openEditSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Number: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(numberText),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Nationality: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(nationalityText),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Season stats – ${widget.division.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_statsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_statsError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _statsError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (_racesEntered == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No classified results yet for this driver in this division.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else ...[
                    Text('Races entered: $_racesEntered'),
                    Text('Wins: $_wins'),
                    Text('Podiums: $_podiums'),
                    Text('Pole positions: $_polePositions'),
                    Text('Fastest laps: $_fastestLaps'),
                    Text('Gained positions: $_totalGainedPositions'),
                    Text(
                        'Average finish position: ${_averagePosition.toStringAsFixed(2)}'),
                    Text('Total points: $_totalPoints'),
                    Text(
                        'Points per race: ${_pointsPerRace.toStringAsFixed(2)}'),
                    Text('Penalty points: $_totalPenaltyPoints'),
                    const SizedBox(height: 16),
                    const Text(
                      'Race-by-race results',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._raceStats.map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${r.eventName}: P${r.position} – '
                          '${r.totalPoints} pts '
                          '(Base ${r.basePoints}, Penalties ${r.penaltyPoints})',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaceStat {
  final String eventName;
  final int position;
  final int basePoints;
  final int penaltyPoints;
  final int totalPoints;

  _RaceStat({
    required this.eventName,
    required this.position,
    required this.basePoints,
    required this.penaltyPoints,
    required this.totalPoints,
  });
}

class _EventEntry {
  final String driverId;
  final int baseTimeMs;
  final int adjustedTimeMs;

  _EventEntry({
    required this.driverId,
    required this.baseTimeMs,
    required this.adjustedTimeMs,
  });
}
