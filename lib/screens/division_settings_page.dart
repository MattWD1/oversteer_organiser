// lib/screens/division_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../theme/app_theme.dart';

class DivisionSettingsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final Division division;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;

  const DivisionSettingsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.division,
    required this.competitionRepository,
    required this.eventRepository,
  });

  @override
  State<DivisionSettingsPage> createState() => _DivisionSettingsPageState();
}

class _DivisionSettingsPageState extends State<DivisionSettingsPage> {
  // Competition color
  late Color _selectedColor;
  final TextEditingController _hexController = TextEditingController();

  // Penalty points thresholds
  final TextEditingController _qualiBanPointsController =
      TextEditingController(text: '12');
  final TextEditingController _raceBanPointsController =
      TextEditingController(text: '24');

  // Ranking settings
  bool _showDriverPositionChange = false;
  bool _showConstructorPositionChange = false;

  // Session settings
  bool _showPodiumInPreview = false;

  // Race format points (positions 1-20)
  final List<TextEditingController> _racePointsControllers = List.generate(
    20,
    (index) {
      // Default F1 points for top 10, 0 for rest
      final defaultPoints = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
      final value = index < 10 ? defaultPoints[index] : 0;
      return TextEditingController(text: value.toString());
    },
  );

  // Sprint format points (positions 1-20)
  final List<TextEditingController> _sprintPointsControllers = List.generate(
    20,
    (index) {
      // Default sprint points for top 8
      final defaultPoints = [8, 7, 6, 5, 4, 3, 2, 1];
      final value = index < 8 ? defaultPoints[index] : 0;
      return TextEditingController(text: value.toString());
    },
  );

  // Qualifying format points (positions 1-20)
  final List<TextEditingController> _qualifyingPointsControllers =
      List.generate(
    20,
    (index) {
      // Default no qualifying points
      return TextEditingController(text: '0');
    },
  );

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.league.themeColor;
    _hexController.text = _colorToHex(_selectedColor);
  }

  @override
  void dispose() {
    _hexController.dispose();
    _qualiBanPointsController.dispose();
    _raceBanPointsController.dispose();
    for (final controller in _racePointsControllers) {
      controller.dispose();
    }
    for (final controller in _sprintPointsControllers) {
      controller.dispose();
    }
    for (final controller in _qualifyingPointsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  Color? _hexToColor(String hex) {
    try {
      final hexCode = hex.replaceAll('#', '');
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('Choose Competition Colour'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(tempColor);
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    ).then((selectedColor) {
      if (selectedColor != null) {
        setState(() {
          _selectedColor = selectedColor;
          _hexController.text = _colorToHex(selectedColor);
        });
      }
    });
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      setState(() {
        _selectedColor = color;
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.league.themeColor,
        ),
      ),
    );
  }

  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompetitionInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Competition Information'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Competition Colour:'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hexController,
                  decoration: const InputDecoration(
                    labelText: 'Hex Code',
                    hintText: '#FF0000',
                    prefixText: '#',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 7,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[#0-9A-Fa-f]')),
                  ],
                  onChanged: _onHexChanged,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _showColorPicker,
                child: const Text('Colour Wheel'),
              ),
            ],
          ),
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildRulesetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Ruleset'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _qualiBanPointsController,
            decoration: const InputDecoration(
              labelText: 'Qualifying Ban Penalty Points',
              hintText: 'e.g., 12',
              border: OutlineInputBorder(),
              helperText: 'Points required for a qualifying ban',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _raceBanPointsController,
            decoration: const InputDecoration(
              labelText: 'Race Ban Penalty Points',
              hintText: 'e.g., 24',
              border: OutlineInputBorder(),
              helperText: 'Points required for a race ban',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildPointsSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Points Settings'),
        ExpansionTile(
          title: const Text('Race Format'),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(20, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('P${index + 1}:'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _racePointsControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Points',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('Sprint Format'),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(20, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('P${index + 1}:'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _sprintPointsControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Points',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('Qualifying Format'),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(20, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('P${index + 1}:'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _qualifyingPointsControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Points',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildRankingSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Ranking Settings'),
        CheckboxListTile(
          title: const Text('Show position change from last race for drivers'),
          subtitle: const Text(
            'Displays arrows and position changes in driver rankings',
          ),
          value: _showDriverPositionChange,
          onChanged: (value) {
            setState(() {
              _showDriverPositionChange = value ?? false;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'E.g. 1st after round 1, 2nd after round 2 = ⬇️ 1 (red)\n'
            'E.g. 2nd after round 1, 1st after round 2 = ⬆️ 1 (green)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title:
              const Text('Show position change from last race for constructors'),
          subtitle: const Text(
            'Displays arrows and position changes in constructor rankings',
          ),
          value: _showConstructorPositionChange,
          onChanged: (value) {
            setState(() {
              _showConstructorPositionChange = value ?? false;
            });
          },
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildSessionSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Session Settings'),
        CheckboxListTile(
          title: const Text('Show Podium in Preview'),
          subtitle: const Text(
            'Displays the top 3 finishers when viewing all events',
          ),
          value: _showPodiumInPreview,
          onChanged: (value) {
            setState(() {
              _showPodiumInPreview = value ?? false;
            });
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      primaryColor: widget.league.themeColor,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.division.name} Settings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved successfully'),
                  ),
                );
              },
              tooltip: 'Save Settings',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Settings'),
              _buildCompetitionInformationSection(),
              _buildRulesetSection(),
              _buildPointsSettingsSection(),
              _buildRankingSettingsSection(),
              _buildSessionSettingsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
