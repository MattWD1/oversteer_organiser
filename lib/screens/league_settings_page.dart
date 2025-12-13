// lib/screens/league_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/league.dart';
import '../repositories/competition_repository.dart';
import '../repositories/league_repository.dart';

class LeagueSettingsPage extends StatefulWidget {
  final League league;
  final CompetitionRepository competitionRepository;
  final LeagueRepository leagueRepository;

  const LeagueSettingsPage({
    super.key,
    required this.league,
    required this.competitionRepository,
    required this.leagueRepository,
  });

  @override
  State<LeagueSettingsPage> createState() => _LeagueSettingsPageState();
}

class _LeagueSettingsPageState extends State<LeagueSettingsPage> {
  // League color
  late Color _selectedColor;
  final TextEditingController _hexController = TextEditingController();

  // Generated codes
  String? _memberCode;
  String? _adminCode;

  // Social media URLs
  late TextEditingController _tiktokController;
  late TextEditingController _twitchController;
  late TextEditingController _instagramController;
  late TextEditingController _youtubeController;
  late TextEditingController _twitterController;
  late TextEditingController _discordController;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.league.themeColor;
    _hexController.text = _colorToHex(_selectedColor);

    // Initialize social media controllers with existing values
    _tiktokController = TextEditingController(text: widget.league.tiktokUrl ?? '');
    _twitchController = TextEditingController(text: widget.league.twitchUrl ?? '');
    _instagramController = TextEditingController(text: widget.league.instagramUrl ?? '');
    _youtubeController = TextEditingController(text: widget.league.youtubeUrl ?? '');
    _twitterController = TextEditingController(text: widget.league.twitterUrl ?? '');
    _discordController = TextEditingController(text: widget.league.discordUrl ?? '');
  }

  @override
  void dispose() {
    _hexController.dispose();
    _tiktokController.dispose();
    _twitchController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _twitterController.dispose();
    _discordController.dispose();
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

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubHeader('Social Media'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add your social media links - they will appear as clickable icons',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _buildSocialMediaField(
                label: 'TikTok',
                iconAsset: 'assets/flags/socialmedia/tiktok.svg',
                color: Colors.black,
                controller: _tiktokController,
                hint: 'https://tiktok.com/@yourhandle',
              ),
              const SizedBox(height: 12),
              _buildSocialMediaField(
                label: 'Twitch',
                iconAsset: 'assets/flags/socialmedia/twitch.svg',
                color: const Color(0xFF9146FF),
                controller: _twitchController,
                hint: 'https://twitch.tv/yourhandle',
              ),
              const SizedBox(height: 12),
              _buildSocialMediaField(
                label: 'Instagram',
                iconAsset: 'assets/flags/socialmedia/instagram.svg',
                color: const Color(0xFFE4405F),
                controller: _instagramController,
                hint: 'https://instagram.com/yourhandle',
              ),
              const SizedBox(height: 12),
              _buildSocialMediaField(
                label: 'YouTube',
                iconAsset: 'assets/flags/socialmedia/youtube.svg',
                color: const Color(0xFFFF0000),
                controller: _youtubeController,
                hint: 'https://youtube.com/@yourhandle',
              ),
              const SizedBox(height: 12),
              _buildSocialMediaField(
                label: 'X',
                iconAsset: 'assets/flags/socialmedia/x.svg',
                color: Colors.black,
                controller: _twitterController,
                hint: 'https://x.com/yourhandle',
              ),
              const SizedBox(height: 12),
              _buildSocialMediaField(
                label: 'Discord',
                iconAsset: 'assets/flags/socialmedia/discord.svg',
                color: const Color(0xFF5865F2),
                controller: _discordController,
                hint: 'https://discord.gg/yourinvite',
              ),
            ],
          ),
        ),
        const Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildSocialMediaField({
    required String label,
    required String iconAsset,
    required Color color,
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              iconAsset,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              // Save the selected color to the league
              // Convert color to ARGB32 format (0xAARRGGBB) using new color API
              final a = (_selectedColor.a * 255.0).round().clamp(0, 255);
              final r = (_selectedColor.r * 255.0).round().clamp(0, 255);
              final g = (_selectedColor.g * 255.0).round().clamp(0, 255);
              final b = (_selectedColor.b * 255.0).round().clamp(0, 255);
              final colorValue = (a << 24) | (r << 16) | (g << 8) | (b << 0);

              await widget.leagueRepository.updateLeagueThemeColor(
                widget.league.id,
                colorValue,
              );

              // Save social media URLs
              await widget.leagueRepository.updateLeagueSocialMedia(
                widget.league.id,
                tiktokUrl: _tiktokController.text.trim().isEmpty ? null : _tiktokController.text.trim(),
                twitchUrl: _twitchController.text.trim().isEmpty ? null : _twitchController.text.trim(),
                instagramUrl: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
                youtubeUrl: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
                twitterUrl: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
                discordUrl: _discordController.text.trim().isEmpty ? null : _discordController.text.trim(),
              );

              if (!mounted) return;

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Settings saved! Re-enter the league to see changes.'),
                  duration: Duration(seconds: 3),
                ),
              );

              // Return true to signal that settings were changed
              navigator.pop(true);
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
            _buildSocialMediaSection(),
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
