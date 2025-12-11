// lib/screens/league_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/league.dart';
import '../repositories/competition_repository.dart';

class LeagueSettingsPage extends StatefulWidget {
  final League league;
  final CompetitionRepository competitionRepository;

  const LeagueSettingsPage({
    super.key,
    required this.league,
    required this.competitionRepository,
  });

  @override
  State<LeagueSettingsPage> createState() => _LeagueSettingsPageState();
}

class _LeagueSettingsPageState extends State<LeagueSettingsPage> {
  // League color
  Color _selectedColor = Colors.blue;
  final TextEditingController _hexController = TextEditingController();

  // Generated codes
  String? _memberCode;
  String? _adminCode;

  @override
  void initState() {
    super.initState();
    _hexController.text = _colorToHex(_selectedColor);
  }

  @override
  void dispose() {
    _hexController.dispose();
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
          title: const Text('Choose League Colour'),
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

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      8,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }

  void _generateMemberCode() {
    setState(() {
      _memberCode = _generateCode();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Member invite code generated'),
      ),
    );
  }

  void _generateAdminCode() {
    setState(() {
      _adminCode = _generateCode();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Admin invite code generated'),
      ),
    );
  }

  void _copyToClipboard(String code, String type) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type code copied to clipboard'),
      ),
    );
  }

  Future<void> _manageCompetitionsVisibility() async {
    // Get all divisions for this league
    final divisions = await widget.competitionRepository
        .getDivisionsForLeague(widget.league.id);

    if (!mounted) return;

    if (divisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No divisions found for this league'),
        ),
      );
      return;
    }

    // Track which divisions are hidden (for demo purposes, using local state)
    final Set<String> hiddenDivisions = {};

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Competitions'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select which divisions contribute to the Overall Constructors Championship:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: divisions.length,
                        itemBuilder: (context, index) {
                          final division = divisions[index];
                          final isVisible =
                              !hiddenDivisions.contains(division.id);

                          return CheckboxListTile(
                            title: Text(division.name),
                            subtitle: Text(
                              isVisible
                                  ? 'Contributing to Overall Table'
                                  : 'Hidden from Overall Table',
                              style: TextStyle(
                                fontSize: 12,
                                color: isVisible ? Colors.green : Colors.grey,
                              ),
                            ),
                            value: isVisible,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  hiddenDivisions.remove(division.id);
                                } else {
                                  hiddenDivisions.add(division.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // In a real app, save the hiddenDivisions to a repository
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Competition visibility settings saved'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.red,
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

  Widget _buildChangeLeagueColourSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Change League Colour'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('League Colour:'),
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

  Widget _buildInviteToViewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Invite to View'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate a code for others to join this league as a MEMBER (view-only access)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _generateMemberCode,
                icon: Icon(Icons.refresh),
                label: const Text('Generate Code'),
              ),
              if (_memberCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _memberCode!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_memberCode!, 'Member'),
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildInviteAsAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Invite as Admin'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate a code for others to join this league as an ADMIN (full access)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _generateAdminCode,
                icon: Icon(Icons.refresh),
                label: const Text('Generate Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_adminCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _adminCode!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyToClipboard(_adminCode!, 'Admin'),
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildCompetitionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Competitions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage which competitions contribute to the Overall Constructors Championship',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _manageCompetitionsVisibility,
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('Hide Competitions from Overall Table'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.league.name} Settings'),
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
            _buildChangeLeagueColourSection(),
            _buildInviteToViewSection(),
            _buildInviteAsAdminSection(),
            _buildCompetitionsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
