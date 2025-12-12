// lib/screens/session_results_view_page.dart

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/driver.dart';
import '../models/league.dart';
import '../models/session_result.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../theme/app_theme.dart';

class SessionResultsViewPage extends StatefulWidget {
  final League league;
  final Event event;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;

  const SessionResultsViewPage({
    super.key,
    required this.league,
    required this.event,
    required this.driverRepository,
    required this.sessionResultRepository,
  });

  @override
  State<SessionResultsViewPage> createState() => _SessionResultsViewPageState();
}

class _SessionResultsViewPageState extends State<SessionResultsViewPage> {
  int _selectedTab = 0; // 0 = Race, 1 = Qualifying
  bool _isLoading = true;
  List<Driver> _allDrivers = [];
  List<SessionResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drivers = await widget.driverRepository.getDriversForEvent(widget.event.id);
      final results = widget.sessionResultRepository.getResultsForEvent(widget.event.id);

      setState(() {
        _allDrivers = drivers;
        _results = results.toList()
          ..sort((a, b) {
            if (a.finishPosition == null && b.finishPosition == null) return 0;
            if (a.finishPosition == null) return 1;
            if (b.finishPosition == null) return -1;
            return a.finishPosition!.compareTo(b.finishPosition!);
          });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Driver? _getDriver(String driverId) {
    try {
      return _allDrivers.firstWhere((d) => d.id == driverId);
    } catch (e) {
      return null;
    }
  }

  SessionResult? _getFastestLapResult() {
    try {
      return _results.firstWhere((r) => r.hasFastestLap);
    } catch (e) {
      return null;
    }
  }

  SessionResult? _getPoleResult() {
    try {
      return _results.firstWhere((r) => r.gridPosition == 1 && r.poleLapMillis != null);
    } catch (e) {
      return null;
    }
  }

  String _formatTime(int? ms) {
    if (ms == null) return '--:--:--';
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final millis = duration.inMilliseconds % 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppTheme(
        primaryColor: widget.league.themeColor,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.grey.shade900,
                  widget.league.themeColor.withValues(alpha: 0.4),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(color: widget.league.themeColor),
            ),
          ),
        ),
      );
    }

    final fastestLap = _getFastestLapResult();
    final pole = _getPoleResult();

    return AppTheme(
      primaryColor: widget.league.themeColor,
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey.shade900,
              widget.league.themeColor.withValues(alpha: 0.4),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with event name
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  widget.event.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Share results
                    },
                  ),
                ],
              ),
              // Session type banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.league.themeColor.withValues(alpha: 0.4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.league.themeColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.event.flagEmoji != null) ...[
                      Text(
                        widget.event.flagEmoji!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _selectedTab == 0 ? 'RACE' : 'QUALIFYING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Stats section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade900, Colors.black87],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.league.themeColor.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.league.themeColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Driver of the day (placeholder - you can implement voting system later)
                    _buildStatRow(
                      'DRIVER OF THE DAY',
                      _results.isNotEmpty && _results[0].finishPosition == 1
                          ? _getDriver(_results[0].driverId)?.name ?? 'Unknown'
                          : '--',
                      Colors.amber,
                      Icons.emoji_events,
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    // Fastest lap
                    _buildStatRow(
                      'FASTEST LAP',
                      fastestLap != null
                          ? '${_formatTime(fastestLap.fastestLapMillis)} • ${_getDriver(fastestLap.driverId)?.name ?? "Unknown"}'
                          : '--',
                      Colors.purple.shade400,
                      Icons.speed,
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    // Pole position
                    _buildStatRow(
                      'POLE',
                      pole != null
                          ? '${_formatTime(pole.poleLapMillis)} • ${_getDriver(pole.driverId)?.name ?? "Unknown"}'
                          : '--',
                      Colors.green.shade400,
                      Icons.flag,
                    ),
                  ],
                ),
              ),
              // Results table header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 40,
                      child: Text(
                        'Pos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Name',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 60,
                      child: Text(
                        'Grid',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Results list
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      final driver = _getDriver(result.driverId);
                      final position = result.finishPosition ?? (index + 1);

                      // Color for driver number based on position
                      Color numberColor = Colors.white;
                      if (position == 1) numberColor = Colors.amber;
                      else if (position == 2) numberColor = Colors.grey.shade400;
                      else if (position == 3) numberColor = Colors.orange.shade800;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white10,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Position
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$position',
                                style: TextStyle(
                                  color: numberColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            // Driver number and name
                            Expanded(
                              child: Row(
                                children: [
                                  // Driver number with color
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: numberColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: numberColor, width: 1),
                                    ),
                                    child: Text(
                                      driver?.number?.toString() ?? '--',
                                      style: TextStyle(
                                        color: numberColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Country flag (placeholder - you can add flag emojis later)
                                  Text(
                                    '🏁', // Placeholder flag
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  // Driver name
                                  Expanded(
                                    child: Text(
                                      driver?.name ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Grid position
                            SizedBox(
                              width: 60,
                              child: Text(
                                result.gridPosition?.toString() ?? '--',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Bottom tab bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 0
                                ? LinearGradient(
                                    colors: [widget.league.themeColor.withValues(alpha: 0.85), widget.league.themeColor.withValues(alpha: 0.4)],
                                  )
                                : null,
                            border: Border(
                              top: BorderSide(
                                color: _selectedTab == 0 ? widget.league.themeColor.withValues(alpha: 0.9) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sports_score,
                                color: _selectedTab == 0 ? Colors.white : Colors.grey.shade600,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Race',
                                style: TextStyle(
                                  color: _selectedTab == 0 ? Colors.white : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _selectedTab == 1
                                ? LinearGradient(
                                    colors: [Colors.red.shade700, Colors.red.shade900],
                                  )
                                : null,
                            border: Border(
                              top: BorderSide(
                                color: _selectedTab == 1 ? Colors.red.shade600 : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                color: _selectedTab == 1 ? Colors.white : Colors.grey.shade600,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Qualifying',
                                style: TextStyle(
                                  color: _selectedTab == 1 ? Colors.white : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildStatRow(String label, String value, Color accentColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
