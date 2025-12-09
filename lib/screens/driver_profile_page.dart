// lib/screens/driver_profile_page.dart

import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/division.dart';
// ignore: unused_import
import '../models/event.dart';
import '../models/session_result.dart';
// ignore: unused_import
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
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _nationalityController;

  bool _isLoadingStats = true;
  String? _statsError;

  int _races = 0;
  int _wins = 0;
  int _podiums = 0;
  int _fastestLaps = 0;
  int _positionsGained = 0;
  double _avgFinish = 0;
  double _pointsPerRace = 0;
  int _penaltyPoints = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _numberController = TextEditingController(
      text: widget.driver.number?.toString() ?? '',
    );
    _nationalityController = TextEditingController(
      text: widget.driver.nationality ?? '',
    );
    _loadStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _nationalityController.dispose();
    super.dispose();
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

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final events = await widget.eventRepository
          .getEventsForDivision(widget.division.id);

      int races = 0;
      int wins = 0;
      int podiums = 0;
      int fastestLaps = 0;
      int positionsGained = 0;
      int totalFinish = 0;
      int totalPoints = 0;
      int penaltyPoints = 0;

      for (final event in events) {
        final results =
            widget.sessionResultRepository.getResultsForEvent(event.id);

        final result = results
            .where((r) => r.driverId == widget.driver.id)
            .cast<SessionResult?>()
            .firstWhere(
              (r) => r != null,
              orElse: () => null,
            );

        if (result == null) {
          continue;
        }

        races++;

        // Positions gained
        if (result.gridPosition != null && result.finishPosition != null) {
          positionsGained +=
              (result.gridPosition! - result.finishPosition!);
        }

        // Finish stats
        if (result.finishPosition != null) {
          final finish = result.finishPosition!;
          totalFinish += finish;
          if (finish == 1) wins++;
          if (finish <= 3) podiums++;
        }

        // Fastest lap flag
        if (result.hasFastestLap == true) {
          fastestLaps++;
        }

        // Base points
        final basePoints =
            _pointsForFinish(result.finishPosition ?? 0);
        int eventPoints = basePoints;

        // Penalty points from repository
        final penalties =
            widget.penaltyRepository.getPenaltiesForEvent(event.id);
        for (final p in penalties) {
          if (p.driverId == widget.driver.id && p.type == 'Points') {
            eventPoints += p.value;
            penaltyPoints += p.value;
          }
        }

        totalPoints += eventPoints;
      }

      setState(() {
        _races = races;
        _wins = wins;
        _podiums = podiums;
        _fastestLaps = fastestLaps;
        _positionsGained = positionsGained;
        _penaltyPoints = penaltyPoints;
        _avgFinish =
            races > 0 ? totalFinish / races : 0.0;
        _pointsPerRace =
            races > 0 ? totalPoints / races : 0.0;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
        _statsError = 'Error loading stats: $e';
      });
    }
  }

  // --- Nationality picker ---

  static const List<String> _countries = [
    '🇦🇫 Afghanistan',
    '🇦🇱 Albania',
    '🇩🇿 Algeria',
    '🇦🇩 Andorra',
    '🇦🇴 Angola',
    '🇦🇬 Antigua and Barbuda',
    '🇦🇷 Argentina',
    '🇦🇲 Armenia',
    '🇦🇺 Australia',
    '🇦🇹 Austria',
    '🇦🇿 Azerbaijan',
    '🇧🇸 Bahamas',
    '🇧🇭 Bahrain',
    '🇧🇩 Bangladesh',
    '🇧🇧 Barbados',
    '🇧🇾 Belarus',
    '🇧🇪 Belgium',
    '🇧🇿 Belize',
    '🇧🇯 Benin',
    '🇧🇹 Bhutan',
    '🇧🇴 Bolivia',
    '🇧🇦 Bosnia and Herzegovina',
    '🇧🇼 Botswana',
    '🇧🇷 Brazil',
    '🇧🇳 Brunei',
    '🇧🇬 Bulgaria',
    '🇧4 Burkina Faso',
    '🇧🇮 Burundi',
    '🇨🇻 Cabo Verde',
    '🇰🇭 Cambodia',
    '🇨🇲 Cameroon',
    '🇨🇦 Canada',
    '🇨🇫 Central African Republic',
    '🇹🇩 Chad',
    '🇨🇱 Chile',
    '🇨🇳 China',
    '🇨🇴 Colombia',
    '🇰🇲 Comoros',
    '🇨🇩 Congo (DRC)',
    '🇨🇬 Congo (Republic)',
    '🇨🇷 Costa Rica',
    '🇨🇮 Côte d\'Ivoire',
    '🇭🇷 Croatia',
    '🇨🇺 Cuba',
    '🇨🇾 Cyprus',
    '🇨🇿 Czech Republic',
    '🇩🇰 Denmark',
    '🇩🇯 Djibouti',
    '🇩🇲 Dominica',
    '🇩🇴 Dominican Republic',
    '🇹🇱 East Timor',
    '🇪🇨 Ecuador',
    '🇪🇬 Egypt',
    '🇸🇻 El Salvador',
    '🇬🇶 Equatorial Guinea',
    '🇪🇷 Eritrea',
    '🇪🇪 Estonia',
    '🇸🇿 Eswatini',
    '🇪🇹 Ethiopia',
    '🇫🇯 Fiji',
    '🇫🇮 Finland',
    '🇫🇷 France',
    '🇬🇦 Gabon',
    '🇬🇲 Gambia',
    '🇬🇪 Georgia',
    '🇩🇪 Germany',
    '🇬🇭 Ghana',
    '🇬🇷 Greece',
    '🇬🇩 Grenada',
    '🇬🇹 Guatemala',
    '🇬🇳 Guinea',
    '🇬🇼 Guinea-Bissau',
    '🇬🇾 Guyana',
    '🇭🇹 Haiti',
    '🇭🇳 Honduras',
    '🇭🇺 Hungary',
    '🇮🇸 Iceland',
    '🇮🇳 India',
    '🇮🇩 Indonesia',
    '🇮🇷 Iran',
    '🇮🇶 Iraq',
    '🇮🇪 Ireland',
    '🇮🇱 Israel',
    '🇮🇹 Italy',
    '🇯🇲 Jamaica',
    '🇯🇵 Japan',
    '🇯🇴 Jordan',
    '🇰🇿 Kazakhstan',
    '🇰🇪 Kenya',
    '🇰🇮 Kiribati',
    '🇰🇵 Korea (North)',
    '🇰🇷 Korea (South)',
    '🇽🇰 Kosovo',
    '🇰🇼 Kuwait',
    '🇰🇬 Kyrgyzstan',
    '🇱🇦 Laos',
    '🇱🇻 Latvia',
    '🇱🇧 Lebanon',
    '🇱🇸 Lesotho',
    '🇱🇷 Liberia',
    '🇱🇾 Libya',
    '🇱🇮 Liechtenstein',
    '🇱🇹 Lithuania',
    '🇱🇺 Luxembourg',
    '🇲🇬 Madagascar',
    '🇲🇼 Malawi',
    '🇲🇾 Malaysia',
    '🇲🇻 Maldives',
    '🇲🇱 Mali',
    '🇲🇹 Malta',
    '🇲🇭 Marshall Islands',
    '🇲🇷 Mauritania',
    '🇲🇺 Mauritius',
    '🇲🇽 Mexico',
    '🇫🇲 Micronesia',
    '🇲🇩 Moldova',
    '🇲🇨 Monaco',
    '🇲🇳 Mongolia',
    '🇲🇪 Montenegro',
    '🇲🇦 Morocco',
    '🇲🇿 Mozambique',
    '🇲🇲 Myanmar',
    '🇳🇦 Namibia',
    '🇳🇷 Nauru',
    '🇳🇵 Nepal',
    '🇳🇱 Netherlands',
    '🇳🇿 New Zealand',
    '🇳🇮 Nicaragua',
    '🇳🇪 Niger',
    '🇳🇬 Nigeria',
    '🇲🇰 North Macedonia',
    '🇳🇴 Norway',
    '🇴🇲 Oman',
    '🇵🇰 Pakistan',
    '🇵🇼 Palau',
    '🇵🇸 Palestine',
    '🇵🇦 Panama',
    '🇵🇬 Papua New Guinea',
    '🇵🇾 Paraguay',
    '🇵🇪 Peru',
    '🇵🇭 Philippines',
    '🇵🇱 Poland',
    '🇵🇹 Portugal',
    '🇶🇦 Qatar',
    '🇷🇴 Romania',
    '🇷🇺 Russia',
    '🇷🇼 Rwanda',
    '🇰🇳 Saint Kitts and Nevis',
    '🇱🇨 Saint Lucia',
    '🇻🇨 Saint Vincent and the Grenadines',
    '🇼🇸 Samoa',
    '🇸🇲 San Marino',
    '🇸🇹 Sao Tome and Principe',
    '🇸🇦 Saudi Arabia',
    '🇸🇳 Senegal',
    '🇷🇸 Serbia',
    '🇸🇨 Seychelles',
    '🇸🇱 Sierra Leone',
    '🇸🇬 Singapore',
    '🇸🇰 Slovakia',
    '🇸🇮 Slovenia',
    '🇸🇧 Solomon Islands',
    '🇸🇴 Somalia',
    '🇿🇦 South Africa',
    '🇸🇸 South Sudan',
    '🇪🇸 Spain',
    '🇱🇰 Sri Lanka',
    '🇸🇩 Sudan',
    '🇸🇷 Suriname',
    '🇸🇪 Sweden',
    '🇨🇭 Switzerland',
    '🇸🇾 Syria',
    '🇹🇼 Taiwan',
    '🇹🇯 Tajikistan',
    '🇹🇿 Tanzania',
    '🇹🇭 Thailand',
    '🇹🇬 Togo',
    '🇹🇴 Tonga',
    '🇹🇹 Trinidad and Tobago',
    '🇹🇳 Tunisia',
    '🇹🇷 Turkey',
    '🇹🇲 Turkmenistan',
    '🇹🇻 Tuvalu',
    '🇺🇬 Uganda',
    '🇺🇦 Ukraine',
    '🇦🇪 United Arab Emirates',
    '🇬🇧 United Kingdom',
    '🇺🇸 United States',
    '🇺🇾 Uruguay',
    '🇺🇿 Uzbekistan',
    '🇻🇺 Vanuatu',
    '🇻🇦 Vatican City',
    '🇻🇪 Venezuela',
    '🇻🇳 Vietnam',
    '🇾🇪 Yemen',
    '🇿🇲 Zambia',
    '🇿🇼 Zimbabwe',
  ];

  void _openNationalityPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String query = '';
        List<String> filtered = List<String>.from(_countries);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void applyFilter(String text) {
              query = text.toLowerCase();
              filtered = _countries
                  .where(
                    (c) => c.toLowerCase().contains(query),
                  )
                  .toList();
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select nationality',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: applyFilter,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final country = filtered[index];
                        return ListTile(
                          title: Text(country),
                          onTap: () {
                            setState(() {
                              _nationalityController.text = country;
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
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

  Widget _buildProfileHeader() {
    final name = _nameController.text.trim().isEmpty
        ? widget.driver.name
        : _nameController.text.trim();

    final numberText = _numberController.text.trim();
    final nationalityText = _nationalityController.text.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (numberText.isNotEmpty)
                    Text(
                      '#$numberText',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  if (nationalityText.isNotEmpty)
                    Text(
                      nationalityText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableDetails() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Driver number',
                hintText: 'e.g. 44',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openNationalityPicker,
              child: AbsorbPointer(
                child: TextField(
                  controller: _nationalityController,
                  decoration: const InputDecoration(
                    labelText: 'Nationality',
                    hintText: 'Tap to select',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_statsError != null) {
      return Center(child: Text(_statsError!));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Season stats (this division)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _statTile('Races', _races.toString()),
                _statTile('Wins', _wins.toString()),
                _statTile('Podiums', _podiums.toString()),
                _statTile('Fastest laps', _fastestLaps.toString()),
                _statTile('Pos. gained', _positionsGained.toString()),
                _statTile(
                  'Avg. finish',
                  _races > 0 ? _avgFinish.toStringAsFixed(2) : '-',
                ),
                _statTile(
                  'Pts / race',
                  _races > 0 ? _pointsPerRace.toStringAsFixed(2) : '-',
                ),
                _statTile('Penalty points', _penaltyPoints.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver – ${widget.driver.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildEditableDetails(),
            _buildStatsCard(),
          ],
        ),
      ),
    );
  }
}
