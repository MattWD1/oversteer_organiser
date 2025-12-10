// lib/screens/events_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'session_page.dart';
import 'driver_profile_page.dart';
import 'team_profile_page.dart';

import '../models/league.dart';
import '../models/competition.dart';
import '../models/division.dart';
import '../models/event.dart';
import '../models/driver.dart';
import '../models/session_result.dart';
import '../models/penalty.dart';

import '../repositories/competition_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/session_result_repository.dart';
import '../repositories/validation_issue_repository.dart';
import '../repositories/penalty_repository.dart';

// ---------- F1 25 Tracks + Flags ----------

class _F1TrackOption {
  final String trackName;
  final String countryName;
  final String flagEmoji;

  const _F1TrackOption({
    required this.trackName,
    required this.countryName,
    required this.flagEmoji,
  });
}

const List<_F1TrackOption> _f1Tracks = [
  _F1TrackOption(
    trackName: 'Albert Park, Melbourne',
    countryName: 'Australia',
    flagEmoji: '🇦🇺',
  ),
  _F1TrackOption(
    trackName: 'Shanghai International Circuit',
    countryName: 'China',
    flagEmoji: '🇨🇳',
  ),
  _F1TrackOption(
    trackName: 'Suzuka',
    countryName: 'Japan',
    flagEmoji: '🇯🇵',
  ),
  _F1TrackOption(
    trackName: 'Bahrain International Circuit',
    countryName: 'Bahrain',
    flagEmoji: '🇧🇭',
  ),
  _F1TrackOption(
    trackName: 'Jeddah Corniche Circuit',
    countryName: 'Saudi Arabia',
    flagEmoji: '🇸🇦',
  ),
  _F1TrackOption(
    trackName: 'Miami International Autodrome',
    countryName: 'United States',
    flagEmoji: '🇺🇸',
  ),
  _F1TrackOption(
    trackName: 'Imola, Autodromo Enzo e Dino Ferrari',
    countryName: 'Italy',
    flagEmoji: '🇮🇹',
  ),
  _F1TrackOption(
    trackName: 'Monte Carlo Grand Prix Circuit',
    countryName: 'Monaco',
    flagEmoji: '🇲🇨',
  ),
  _F1TrackOption(
    trackName: 'Circuit de Barcelona-Catalunya',
    countryName: 'Spain',
    flagEmoji: '🇪🇸',
  ),
  _F1TrackOption(
    trackName: 'Circuit Gilles Villeneuve, Montreal',
    countryName: 'Canada',
    flagEmoji: '🇨🇦',
  ),
  _F1TrackOption(
    trackName: 'Red Bull Ring',
    countryName: 'Austria',
    flagEmoji: '🇦🇹',
  ),
  _F1TrackOption(
    trackName: 'Silverstone',
    countryName: 'Great Britain',
    flagEmoji: '🇬🇧',
  ),
  _F1TrackOption(
    trackName: 'Circuit de Spa-Francorchamps',
    countryName: 'Belgium',
    flagEmoji: '🇧🇪',
  ),
  _F1TrackOption(
    trackName: 'Hungaroring',
    countryName: 'Hungary',
    flagEmoji: '🇭🇺',
  ),
  _F1TrackOption(
    trackName: 'Circuit Zandvoort',
    countryName: 'Netherlands',
    flagEmoji: '🇳🇱',
  ),
  _F1TrackOption(
    trackName: 'Monza',
    countryName: 'Italy',
    flagEmoji: '🇮🇹',
  ),
  _F1TrackOption(
    trackName: 'Baku City Circuit',
    countryName: 'Azerbaijan',
    flagEmoji: '🇦🇿',
  ),
  _F1TrackOption(
    trackName: 'Singapore Marina Bay',
    countryName: 'Singapore',
    flagEmoji: '🇸🇬',
  ),
  _F1TrackOption(
    trackName: 'Circuit of the Americas (COTA)',
    countryName: 'United States',
    flagEmoji: '🇺🇸',
  ),
  _F1TrackOption(
    trackName: 'Autódromo Hermanos Rodríguez',
    countryName: 'Mexico',
    flagEmoji: '🇲🇽',
  ),
  _F1TrackOption(
    trackName: 'Autódromo José Carlos Pace (Interlagos)',
    countryName: 'Brazil',
    flagEmoji: '🇧🇷',
  ),
  _F1TrackOption(
    trackName: 'Las Vegas Strip Street Circuit',
    countryName: 'United States',
    flagEmoji: '🇺🇸',
  ),
  _F1TrackOption(
    trackName: 'Lusail International Circuit',
    countryName: 'Qatar',
    flagEmoji: '🇶🇦',
  ),
  _F1TrackOption(
    trackName: 'Yas Marina Circuit',
    countryName: 'Abu Dhabi (UAE)',
    flagEmoji: '🇦🇪',
  ),
];

// ---------- Flag options for custom event ----------

class _FlagOption {
  final String countryName;
  final String flagEmoji;

  const _FlagOption({
    required this.countryName,
    required this.flagEmoji,
  });
}

const List<_FlagOption> _baseFlagOptions = [
  _FlagOption(countryName: 'Afghanistan', flagEmoji: '🇦🇫'),
  _FlagOption(countryName: 'Albania', flagEmoji: '🇦🇱'),
  _FlagOption(countryName: 'Algeria', flagEmoji: '🇩🇿'),
  _FlagOption(countryName: 'Andorra', flagEmoji: '🇦🇩'),
  _FlagOption(countryName: 'Angola', flagEmoji: '🇦🇴'),
  _FlagOption(countryName: 'Antigua and Barbuda', flagEmoji: '🇦🇬'),
  _FlagOption(countryName: 'Argentina', flagEmoji: '🇦🇷'),
  _FlagOption(countryName: 'Armenia', flagEmoji: '🇦🇲'),
  _FlagOption(countryName: 'Australia', flagEmoji: '🇦🇺'),
  _FlagOption(countryName: 'Austria', flagEmoji: '🇦🇹'),
  _FlagOption(countryName: 'Azerbaijan', flagEmoji: '🇦🇿'),
  _FlagOption(countryName: 'Bahamas', flagEmoji: '🇧🇸'),
  _FlagOption(countryName: 'Bahrain', flagEmoji: '🇧🇭'),
  _FlagOption(countryName: 'Bangladesh', flagEmoji: '🇧🇩'),
  _FlagOption(countryName: 'Barbados', flagEmoji: '🇧🇧'),
  _FlagOption(countryName: 'Belarus', flagEmoji: '🇧🇾'),
  _FlagOption(countryName: 'Belgium', flagEmoji: '🇧🇪'),
  _FlagOption(countryName: 'Belize', flagEmoji: '🇧🇿'),
  _FlagOption(countryName: 'Benin', flagEmoji: '🇧🇯'),
  _FlagOption(countryName: 'Bhutan', flagEmoji: '🇧🇹'),
  _FlagOption(countryName: 'Bolivia', flagEmoji: '🇧🇴'),
  _FlagOption(countryName: 'Bosnia and Herzegovina', flagEmoji: '🇧🇦'),
  _FlagOption(countryName: 'Botswana', flagEmoji: '🇧🇼'),
  _FlagOption(countryName: 'Brazil', flagEmoji: '🇧🇷'),
  _FlagOption(countryName: 'Brunei', flagEmoji: '🇧🇳'),
  _FlagOption(countryName: 'Bulgaria', flagEmoji: '🇧🇬'),
  _FlagOption(countryName: 'Burkina Faso', flagEmoji: '🇧🇫'),
  _FlagOption(countryName: 'Burundi', flagEmoji: '🇧🇮'),
  _FlagOption(countryName: 'Cabo Verde', flagEmoji: '🇨🇻'),
  _FlagOption(countryName: 'Cambodia', flagEmoji: '🇰🇭'),
  _FlagOption(countryName: 'Cameroon', flagEmoji: '🇨🇲'),
  _FlagOption(countryName: 'Canada', flagEmoji: '🇨🇦'),
  _FlagOption(countryName: 'Central African Republic', flagEmoji: '🇨🇫'),
  _FlagOption(countryName: 'Chad', flagEmoji: '🇹🇩'),
  _FlagOption(countryName: 'Chile', flagEmoji: '🇨🇱'),
  _FlagOption(countryName: 'China', flagEmoji: '🇨🇳'),
  _FlagOption(countryName: 'Colombia', flagEmoji: '🇨🇴'),
  _FlagOption(countryName: 'Comoros', flagEmoji: '🇰🇲'),
  _FlagOption(countryName: 'Congo (DRC)', flagEmoji: '🇨🇩'),
  _FlagOption(countryName: 'Congo (Republic)', flagEmoji: '🇨🇬'),
  _FlagOption(countryName: 'Costa Rica', flagEmoji: '🇨🇷'),
  _FlagOption(countryName: 'Croatia', flagEmoji: '🇭🇷'),
  _FlagOption(countryName: 'Cuba', flagEmoji: '🇨🇺'),
  _FlagOption(countryName: 'Cyprus', flagEmoji: '🇨🇾'),
  _FlagOption(countryName: 'Czech Republic', flagEmoji: '🇨🇿'),
  _FlagOption(countryName: 'Denmark', flagEmoji: '🇩🇰'),
  _FlagOption(countryName: 'Djibouti', flagEmoji: '🇩🇯'),
  _FlagOption(countryName: 'Dominica', flagEmoji: '🇩🇲'),
  _FlagOption(countryName: 'Dominican Republic', flagEmoji: '🇩🇴'),
  _FlagOption(countryName: 'Ecuador', flagEmoji: '🇪🇨'),
  _FlagOption(countryName: 'Egypt', flagEmoji: '🇪🇬'),
  _FlagOption(countryName: 'El Salvador', flagEmoji: '🇸🇻'),
  _FlagOption(countryName: 'Equatorial Guinea', flagEmoji: '🇬🇶'),
  _FlagOption(countryName: 'Eritrea', flagEmoji: '🇪🇷'),
  _FlagOption(countryName: 'Estonia', flagEmoji: '🇪🇪'),
  _FlagOption(countryName: 'Eswatini', flagEmoji: '🇸🇿'),
  _FlagOption(countryName: 'Ethiopia', flagEmoji: '🇪🇹'),
  _FlagOption(countryName: 'Fiji', flagEmoji: '🇫🇯'),
  _FlagOption(countryName: 'Finland', flagEmoji: '🇫🇮'),
  _FlagOption(countryName: 'France', flagEmoji: '🇫🇷'),
  _FlagOption(countryName: 'Gabon', flagEmoji: '🇬🇦'),
  _FlagOption(countryName: 'Gambia', flagEmoji: '🇬🇲'),
  _FlagOption(countryName: 'Georgia', flagEmoji: '🇬🇪'),
  _FlagOption(countryName: 'Germany', flagEmoji: '🇩🇪'),
  _FlagOption(countryName: 'Ghana', flagEmoji: '🇬🇭'),
  _FlagOption(countryName: 'Greece', flagEmoji: '🇬🇷'),
  _FlagOption(countryName: 'Grenada', flagEmoji: '🇬🇩'),
  _FlagOption(countryName: 'Guatemala', flagEmoji: '🇬🇹'),
  _FlagOption(countryName: 'Guinea', flagEmoji: '🇬🇳'),
  _FlagOption(countryName: 'Guinea-Bissau', flagEmoji: '🇬🇼'),
  _FlagOption(countryName: 'Guyana', flagEmoji: '🇬🇾'),
  _FlagOption(countryName: 'Haiti', flagEmoji: '🇭🇹'),
  _FlagOption(countryName: 'Honduras', flagEmoji: '🇭🇳'),
  _FlagOption(countryName: 'Hong Kong', flagEmoji: '🇭🇰'),
  _FlagOption(countryName: 'Hungary', flagEmoji: '🇭🇺'),
  _FlagOption(countryName: 'Iceland', flagEmoji: '🇮🇸'),
  _FlagOption(countryName: 'India', flagEmoji: '🇮🇳'),
  _FlagOption(countryName: 'Indonesia', flagEmoji: '🇮🇩'),
  _FlagOption(countryName: 'Iran', flagEmoji: '🇮🇷'),
  _FlagOption(countryName: 'Iraq', flagEmoji: '🇮🇶'),
  _FlagOption(countryName: 'Ireland', flagEmoji: '🇮🇪'),
  _FlagOption(countryName: 'Israel', flagEmoji: '🇮🇱'),
  _FlagOption(countryName: 'Italy', flagEmoji: '🇮🇹'),
  _FlagOption(countryName: 'Ivory Coast', flagEmoji: '🇨🇮'),
  _FlagOption(countryName: 'Jamaica', flagEmoji: '🇯🇲'),
  _FlagOption(countryName: 'Japan', flagEmoji: '🇯🇵'),
  _FlagOption(countryName: 'Jordan', flagEmoji: '🇯🇴'),
  _FlagOption(countryName: 'Kazakhstan', flagEmoji: '🇰🇿'),
  _FlagOption(countryName: 'Kenya', flagEmoji: '🇰🇪'),
  _FlagOption(countryName: 'Kiribati', flagEmoji: '🇰🇮'),
  _FlagOption(countryName: 'Kuwait', flagEmoji: '🇰🇼'),
  _FlagOption(countryName: 'Kyrgyzstan', flagEmoji: '🇰🇬'),
  _FlagOption(countryName: 'Laos', flagEmoji: '🇱🇦'),
  _FlagOption(countryName: 'Latvia', flagEmoji: '🇱🇻'),
  _FlagOption(countryName: 'Lebanon', flagEmoji: '🇱🇧'),
  _FlagOption(countryName: 'Lesotho', flagEmoji: '🇱🇸'),
  _FlagOption(countryName: 'Liberia', flagEmoji: '🇱🇷'),
  _FlagOption(countryName: 'Libya', flagEmoji: '🇱🇾'),
  _FlagOption(countryName: 'Liechtenstein', flagEmoji: '🇱🇮'),
  _FlagOption(countryName: 'Lithuania', flagEmoji: '🇱🇹'),
  _FlagOption(countryName: 'Luxembourg', flagEmoji: '🇱🇺'),
  _FlagOption(countryName: 'Macau', flagEmoji: '🇲🇴'),
  _FlagOption(countryName: 'Madagascar', flagEmoji: '🇲🇬'),
  _FlagOption(countryName: 'Malawi', flagEmoji: '🇲🇼'),
  _FlagOption(countryName: 'Malaysia', flagEmoji: '🇲🇾'),
  _FlagOption(countryName: 'Maldives', flagEmoji: '🇲🇻'),
  _FlagOption(countryName: 'Mali', flagEmoji: '🇲🇱'),
  _FlagOption(countryName: 'Malta', flagEmoji: '🇲🇹'),
  _FlagOption(countryName: 'Marshall Islands', flagEmoji: '🇲🇭'),
  _FlagOption(countryName: 'Mauritania', flagEmoji: '🇲🇷'),
  _FlagOption(countryName: 'Mauritius', flagEmoji: '🇲🇺'),
  _FlagOption(countryName: 'Mexico', flagEmoji: '🇲🇽'),
  _FlagOption(countryName: 'Micronesia', flagEmoji: '🇫🇲'),
  _FlagOption(countryName: 'Moldova', flagEmoji: '🇲🇩'),
  _FlagOption(countryName: 'Monaco', flagEmoji: '🇲🇨'),
  _FlagOption(countryName: 'Mongolia', flagEmoji: '🇲🇳'),
  _FlagOption(countryName: 'Montenegro', flagEmoji: '🇲🇪'),
  _FlagOption(countryName: 'Morocco', flagEmoji: '🇲🇦'),
  _FlagOption(countryName: 'Mozambique', flagEmoji: '🇲🇿'),
  _FlagOption(countryName: 'Myanmar', flagEmoji: '🇲🇲'),
  _FlagOption(countryName: 'Namibia', flagEmoji: '🇳🇦'),
  _FlagOption(countryName: 'Nauru', flagEmoji: '🇳🇷'),
  _FlagOption(countryName: 'Nepal', flagEmoji: '🇳🇵'),
  _FlagOption(countryName: 'Netherlands', flagEmoji: '🇳🇱'),
  _FlagOption(countryName: 'New Zealand', flagEmoji: '🇳🇿'),
  _FlagOption(countryName: 'Nicaragua', flagEmoji: '🇳🇮'),
  _FlagOption(countryName: 'Niger', flagEmoji: '🇳🇪'),
  _FlagOption(countryName: 'Nigeria', flagEmoji: '🇳🇬'),
  _FlagOption(countryName: 'North Korea', flagEmoji: '🇰🇵'),
  _FlagOption(countryName: 'North Macedonia', flagEmoji: '🇲🇰'),
  _FlagOption(countryName: 'Norway', flagEmoji: '🇳🇴'),
  _FlagOption(countryName: 'Oman', flagEmoji: '🇴🇲'),
  _FlagOption(countryName: 'Pakistan', flagEmoji: '🇵🇰'),
  _FlagOption(countryName: 'Palau', flagEmoji: '🇵🇼'),
  _FlagOption(countryName: 'Palestine', flagEmoji: '🇵🇸'),
  _FlagOption(countryName: 'Panama', flagEmoji: '🇵🇦'),
  _FlagOption(countryName: 'Papua New Guinea', flagEmoji: '🇵🇬'),
  _FlagOption(countryName: 'Paraguay', flagEmoji: '🇵🇾'),
  _FlagOption(countryName: 'Peru', flagEmoji: '🇵🇪'),
  _FlagOption(countryName: 'Philippines', flagEmoji: '🇵🇭'),
  _FlagOption(countryName: 'Poland', flagEmoji: '🇵🇱'),
  _FlagOption(countryName: 'Portugal', flagEmoji: '🇵🇹'),
  _FlagOption(countryName: 'Puerto Rico', flagEmoji: '🇵🇷'),
  _FlagOption(countryName: 'Qatar', flagEmoji: '🇶🇦'),
  _FlagOption(countryName: 'Romania', flagEmoji: '🇷🇴'),
  _FlagOption(countryName: 'Russia', flagEmoji: '🇷🇺'),
  _FlagOption(countryName: 'Rwanda', flagEmoji: '🇷🇼'),
  _FlagOption(countryName: 'Saint Kitts and Nevis', flagEmoji: '🇰🇳'),
  _FlagOption(countryName: 'Saint Lucia', flagEmoji: '🇱🇨'),
  _FlagOption(countryName: 'Saint Vincent', flagEmoji: '🇻🇨'),
  _FlagOption(countryName: 'Samoa', flagEmoji: '🇼🇸'),
  _FlagOption(countryName: 'San Marino', flagEmoji: '🇸🇲'),
  _FlagOption(countryName: 'Sao Tome and Principe', flagEmoji: '🇸🇹'),
  _FlagOption(countryName: 'Saudi Arabia', flagEmoji: '🇸🇦'),
  _FlagOption(countryName: 'Senegal', flagEmoji: '🇸🇳'),
  _FlagOption(countryName: 'Serbia', flagEmoji: '🇷🇸'),
  _FlagOption(countryName: 'Seychelles', flagEmoji: '🇸🇨'),
  _FlagOption(countryName: 'Sierra Leone', flagEmoji: '🇸🇱'),
  _FlagOption(countryName: 'Singapore', flagEmoji: '🇸🇬'),
  _FlagOption(countryName: 'Slovakia', flagEmoji: '🇸🇰'),
  _FlagOption(countryName: 'Slovenia', flagEmoji: '🇸🇮'),
  _FlagOption(countryName: 'Solomon Islands', flagEmoji: '🇸🇧'),
  _FlagOption(countryName: 'Somalia', flagEmoji: '🇸🇴'),
  _FlagOption(countryName: 'South Africa', flagEmoji: '🇿🇦'),
  _FlagOption(countryName: 'South Korea', flagEmoji: '🇰🇷'),
  _FlagOption(countryName: 'South Sudan', flagEmoji: '🇸🇸'),
  _FlagOption(countryName: 'Spain', flagEmoji: '🇪🇸'),
  _FlagOption(countryName: 'Sri Lanka', flagEmoji: '🇱🇰'),
  _FlagOption(countryName: 'Sudan', flagEmoji: '🇸🇩'),
  _FlagOption(countryName: 'Suriname', flagEmoji: '🇸🇷'),
  _FlagOption(countryName: 'Sweden', flagEmoji: '🇸🇪'),
  _FlagOption(countryName: 'Switzerland', flagEmoji: '🇨🇭'),
  _FlagOption(countryName: 'Syria', flagEmoji: '🇸🇾'),
  _FlagOption(countryName: 'Taiwan', flagEmoji: '🇹🇼'),
  _FlagOption(countryName: 'Tajikistan', flagEmoji: '🇹🇯'),
  _FlagOption(countryName: 'Tanzania', flagEmoji: '🇹🇿'),
  _FlagOption(countryName: 'Thailand', flagEmoji: '🇹🇭'),
  _FlagOption(countryName: 'Timor-Leste', flagEmoji: '🇹🇱'),
  _FlagOption(countryName: 'Togo', flagEmoji: '🇹🇬'),
  _FlagOption(countryName: 'Tonga', flagEmoji: '🇹🇴'),
  _FlagOption(countryName: 'Trinidad and Tobago', flagEmoji: '🇹🇹'),
  _FlagOption(countryName: 'Tunisia', flagEmoji: '🇹🇳'),
  _FlagOption(countryName: 'Turkey', flagEmoji: '🇹🇷'),
  _FlagOption(countryName: 'Turkmenistan', flagEmoji: '🇹🇲'),
  _FlagOption(countryName: 'Tuvalu', flagEmoji: '🇹🇻'),
  _FlagOption(countryName: 'Uganda', flagEmoji: '🇺🇬'),
  _FlagOption(countryName: 'Ukraine', flagEmoji: '🇺🇦'),
  _FlagOption(countryName: 'United Arab Emirates', flagEmoji: '🇦🇪'),
  _FlagOption(countryName: 'United Kingdom', flagEmoji: '🇬🇧'),
  _FlagOption(countryName: 'United States', flagEmoji: '🇺🇸'),
  _FlagOption(countryName: 'Uruguay', flagEmoji: '🇺🇾'),
  _FlagOption(countryName: 'Uzbekistan', flagEmoji: '🇺🇿'),
  _FlagOption(countryName: 'Vanuatu', flagEmoji: '🇻🇺'),
  _FlagOption(countryName: 'Vatican City', flagEmoji: '🇻🇦'),
  _FlagOption(countryName: 'Venezuela', flagEmoji: '🇻🇪'),
  _FlagOption(countryName: 'Vietnam', flagEmoji: '🇻🇳'),
  _FlagOption(countryName: 'Yemen', flagEmoji: '🇾🇪'),
  _FlagOption(countryName: 'Zambia', flagEmoji: '🇿🇲'),
  _FlagOption(countryName: 'Zimbabwe', flagEmoji: '🇿🇼'),
  _FlagOption(countryName: 'Rest of World', flagEmoji: '🌐'),
];

// Local UI-only event (for planning)
class _PlannedEvent {
  final String name;
  final String flagEmoji;

  _PlannedEvent({
    required this.name,
    required this.flagEmoji,
  });
}

// ---------- Standings helper models ----------

class _DriverStanding {
  final String driverId;
  final String driverName;
  int basePoints;
  int penaltyPoints;
  int totalPoints;
  int wins;

  _DriverStanding({
    required this.driverId,
    required this.driverName,
  })  : basePoints = 0,
        penaltyPoints = 0,
        totalPoints = 0,
        wins = 0;
}

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

class EventsPage extends StatefulWidget {
  final League league;
  final Competition competition;
  final Division division;
  final CompetitionRepository competitionRepository;
  final EventRepository eventRepository;
  final DriverRepository driverRepository;
  final SessionResultRepository sessionResultRepository;
  final ValidationIssueRepository validationIssueRepository;
  final PenaltyRepository penaltyRepository;

  const EventsPage({
    super.key,
    required this.league,
    required this.competition,
    required this.division,
    required this.competitionRepository,
    required this.eventRepository,
    required this.driverRepository,
    required this.sessionResultRepository,
    required this.validationIssueRepository,
    required this.penaltyRepository,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Future<List<Event>> _futureEvents;
  final List<_PlannedEvent> _localEvents = [];

  // 0 = Race, 1 = Teams, 2 = Drivers, 3 = Rankings
  int _currentEventsTabIndex = 0;

  // 0 = Drivers' Championship, 1 = Constructors' Championship
  int _rankingsTabIndex = 0;

  // Rankings + division-wide data
  bool _isRankingsLoading = false;
  String? _rankingsError;
  List<_DriverStanding> _driverStandings = [];
  List<_TeamStanding> _teamStandings = [];
  final Map<String, Driver> _driversById = {};
  List<Driver> _divisionDrivers = [];
  List<String> _divisionTeams = [];

  @override
  void initState() {
    super.initState();
    _futureEvents =
        widget.eventRepository.getEventsForDivision(widget.division.id);
    _loadRankingsAndDivisionData();
  }

  Future<void> _refreshEvents() async {
    setState(() {
      _futureEvents =
          widget.eventRepository.getEventsForDivision(widget.division.id);
    });
  }

  String _getEventName(Event event) {
    try {
      final dynamic e = event;
      final value = e.name;
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}
    return 'Event';
  }

  String _getEventFlag(Event event) {
    try {
      final dynamic e = event;
      final value = (e.flagEmoji ?? e.flag ?? e.trackFlag ?? e.countryFlag)
          as String?;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (_) {}
    return '🏁';
  }

  // ---------- Rankings + division data loaders ----------

  String _teamLabelForDriver(Driver? driver) {
    if (driver == null) return 'Unknown Team';
    final name = driver.teamName;
    if (name == null || name.trim().isEmpty) return 'Unknown Team';
    return name;
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

  Future<void> _loadRankingsAndDivisionData() async {
    setState(() {
      _isRankingsLoading = true;
      _rankingsError = null;
      _driverStandings = [];
      _teamStandings = [];
      _divisionDrivers = [];
      _divisionTeams = [];
      _driversById.clear();
    });

    try {
      final events =
          await widget.eventRepository.getEventsForDivision(widget.division.id);

      if (events.isEmpty) {
        setState(() {
          _isRankingsLoading = false;
        });
        return;
      }

      final Map<String, _DriverStanding> driverMap = {};
      final Map<String, _TeamStanding> teamMap = {};
      final Map<String, Driver> allDriversById = {};

      for (final event in events) {
        final List<SessionResult> results =
            widget.sessionResultRepository.getResultsForEvent(event.id);
        if (results.isEmpty) continue;

        final List<Driver> eventDrivers =
            await widget.driverRepository.getDriversForEvent(event.id);

        final Map<String, Driver> driverById = {
          for (final d in eventDrivers) d.id: d,
        };

        // track all drivers in this division
        for (final d in eventDrivers) {
          allDriversById[d.id] = d;
        }

        final List<Penalty> penalties =
            widget.penaltyRepository.getPenaltiesForEvent(event.id);

        final Map<String, int> timePenaltySecondsByDriver = {};
        final Map<String, int> pointsPenaltyByDriver = {};

        for (final p in penalties) {
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

          final driverName = driver?.name ?? 'Unknown driver';
          final teamName = _teamLabelForDriver(driver);
          final timePenSec = timePenaltySecondsByDriver[driverId] ?? 0;
          final adjustedTimeMs = baseTimeMs + timePenSec * 1000;

          eventEntries.add(
            _EventClassificationEntry(
              driverId: driverId,
              driverName: driverName,
              teamName: teamName,
              baseTimeMs: baseTimeMs,
              adjustedTimeMs: adjustedTimeMs,
            ),
          );
        }

        if (eventEntries.isEmpty) continue;

        eventEntries.sort(
          (a, b) => a.adjustedTimeMs.compareTo(b.adjustedTimeMs),
        );

        // award points to drivers + teams
        for (var index = 0; index < eventEntries.length; index++) {
          final entry = eventEntries[index];
          final eventPos = index + 1;
          final basePoints = _pointsForFinish(eventPos);

          final dStanding = driverMap.putIfAbsent(
            entry.driverId,
            () => _DriverStanding(
              driverId: entry.driverId,
              driverName: entry.driverName,
            ),
          );
          dStanding.basePoints += basePoints;
          if (eventPos == 1) dStanding.wins += 1;

          final tStanding = teamMap.putIfAbsent(
            entry.teamName,
            () => _TeamStanding(teamName: entry.teamName),
          );
          tStanding.basePoints += basePoints;
          if (eventPos == 1) tStanding.wins += 1;
        }

        // apply points penalties to both driver and team standings
        pointsPenaltyByDriver.forEach((driverId, penaltyPoints) {
          final driver = driverById[driverId];
          final driverName = driver?.name ?? 'Unknown driver';
          final teamName = _teamLabelForDriver(driver);

          final dStanding = driverMap.putIfAbsent(
            driverId,
            () => _DriverStanding(
              driverId: driverId,
              driverName: driverName,
            ),
          );
          dStanding.penaltyPoints += penaltyPoints;

          final tStanding = teamMap.putIfAbsent(
            teamName,
            () => _TeamStanding(teamName: teamName),
          );
          tStanding.penaltyPoints += penaltyPoints;
        });
      }

      final driverList = driverMap.values.toList();
      for (final s in driverList) {
        s.totalPoints = s.basePoints + s.penaltyPoints;
      }
      driverList.sort((a, b) {
        if (b.totalPoints != a.totalPoints) {
          return b.totalPoints.compareTo(a.totalPoints);
        }
        if (b.wins != a.wins) {
          return b.wins.compareTo(a.wins);
        }
        return a.driverName.compareTo(b.driverName);
      });

      final teamList = teamMap.values.toList();
      for (final s in teamList) {
        s.totalPoints = s.basePoints + s.penaltyPoints;
      }
      teamList.sort((a, b) {
        if (b.totalPoints != a.totalPoints) {
          return b.totalPoints.compareTo(a.totalPoints);
        }
        if (b.wins != a.wins) {
          return b.wins.compareTo(a.wins);
        }
        return a.teamName.compareTo(b.teamName);
      });

      // division-wide driver & team lists
      final allDrivers = allDriversById.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final Set<String> teamNames = {};
      for (final d in allDrivers) {
        final tName = d.teamName?.trim();
        if (tName != null && tName.isNotEmpty) {
          teamNames.add(tName);
        }
      }
      final teamsList = teamNames.toList()..sort();

      if (!mounted) return;
      setState(() {
        _driverStandings = driverList;
        _teamStandings = teamList;
        _divisionDrivers = allDrivers;
        _divisionTeams = teamsList;
        _driversById.addAll(allDriversById);
        _isRankingsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rankingsError = 'Error loading standings: $e';
        _isRankingsLoading = false;
      });
    }
  }

  // ---------- Add event: F1 track picker + custom ----------

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final tracks = _f1Tracks;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select a track for this event',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tracks.length + 1, // + custom option
                  itemBuilder: (context, index) {
                    if (index < tracks.length) {
                      final track = tracks[index];
                      return ListTile(
                        leading: Text(
                          track.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(track.trackName),
                        subtitle: Text(track.countryName),
                        onTap: () {
                          Navigator.of(context).pop();
                          _addPlannedEvent(
                            name: track.trackName,
                            flagEmoji: track.flagEmoji,
                          );
                        },
                      );
                    } else {
                      // Custom option at bottom
                      return ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Custom event…'),
                        subtitle: const Text(
                          'Create your own name and select a flag',
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _showCustomEventDialog();
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomEventDialog() async {
    final nameController = TextEditingController();

    final flagOptions = _baseFlagOptions.toList()
      ..sort((a, b) => a.countryName.compareTo(b.countryName));

    _FlagOption selectedFlag = flagOptions.first;

    final result = await showDialog<_PlannedEvent>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom event'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    maxLength: 50,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Event name',
                      hintText: 'e.g. Reverse Silverstone',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<_FlagOption>(
                    initialValue: selectedFlag, // <- use initialValue
                    decoration: const InputDecoration(
                      labelText: 'Flag / Country',
                    ),
                    items: flagOptions
                        .map(
                          (f) => DropdownMenuItem<_FlagOption>(
                            value: f,
                            child: Row(
                              children: [
                                Text(
                                  f.flagEmoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(f.countryName),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedFlag = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop<_PlannedEvent?>(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event name cannot be empty.'),


                      ),
                      );
                      return;
                    }
                    Navigator.of(context).pop<_PlannedEvent>(
                      _PlannedEvent(
                        name: name,
                        flagEmoji: selectedFlag.flagEmoji,
                      ),
                    );
                  },
                  child: const Text('Add event'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _addPlannedEvent(
        name: result.name,
        flagEmoji: result.flagEmoji,
      );
    }
  }

  void _addPlannedEvent({
    required String name,
    required String flagEmoji,
  }) {
    setState(() {
      _localEvents.add(
        _PlannedEvent(
          name: name,
          flagEmoji: flagEmoji,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "$name" added to this division.'),
      ),
    );
  }

  // ---------- Tabs ----------

  Widget _buildRaceTab() {
    return FutureBuilder<List<Event>>(
      future: _futureEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading events: ${snapshot.error}'),
          );
        }

        final existingEvents = snapshot.data ?? [];
        final totalCount = existingEvents.length + _localEvents.length;

        if (totalCount == 0) {
          return const Center(
            child: Text('No events yet. Tap + to add one.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _refreshEvents();
            await _loadRankingsAndDivisionData();
          },
          child: ListView.builder(
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (index < existingEvents.length) {
                final event = existingEvents[index];
                final name = _getEventName(event);
                final flag = _getEventFlag(event);

                return ListTile(
                  leading: Text(
                    flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SessionPage(
                          event: event,
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
              } else {
                final localIndex = index - existingEvents.length;
                final event = _localEvents[localIndex];

                return ListTile(
                  leading: Text(
                    event.flagEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(event.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Custom/planned event – sessions coming soon.',
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_isRankingsLoading && _divisionTeams.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_divisionTeams.isEmpty) {
      return const Center(
        child: Text(
          'No teams found yet for this division.\n'
          'Teams are derived from drivers entered into events.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankingsAndDivisionData,
      child: ListView.builder(
        itemCount: _divisionTeams.length,
        itemBuilder: (context, index) {
          final name = _divisionTeams[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
              ),
            ),
            title: Text(name),
            subtitle: const Text('Competing in this division'),
          );
        },
      ),
    );
  }

  Widget _buildDriversTab() {
    if (_isRankingsLoading && _divisionDrivers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_divisionDrivers.isEmpty) {
      return const Center(
        child: Text(
          'No drivers found yet for this division.\n'
          'Drivers are derived from session results.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankingsAndDivisionData,
      child: ListView.builder(
        itemCount: _divisionDrivers.length,
        itemBuilder: (context, index) {
          final driver = _divisionDrivers[index];
          final parts = <String>[];

          if (driver.number != null) {
            parts.add('#${driver.number}');
          }
          parts.add(driver.name);
          if (driver.nationality != null && driver.nationality!.isNotEmpty) {
            parts.add('(${driver.nationality})');
          }

          final subtitleParts = <String>[];
          if (driver.teamName != null && driver.teamName!.isNotEmpty) {
            subtitleParts.add(driver.teamName!);
          }

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
              ),
            ),
            title: Text(parts.join(' ')),
            subtitle: subtitleParts.isEmpty
                ? null
                : Text(subtitleParts.join(' • ')),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DriverProfilePage(
                    driver: driver,
                    division: widget.division,
                    eventRepository: widget.eventRepository,
                    sessionResultRepository: widget.sessionResultRepository,
                    penaltyRepository: widget.penaltyRepository,
                    driverRepository: widget.driverRepository,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankingsTab() {
    final showingDrivers = _rankingsTabIndex == 0;

    Widget inner;
    if (_isRankingsLoading) {
      inner = const Center(child: CircularProgressIndicator());
    } else if (_rankingsError != null) {
      inner = Center(child: Text(_rankingsError!));
    } else if ((showingDrivers && _driverStandings.isEmpty) ||
        (!showingDrivers && _teamStandings.isEmpty)) {
      inner = const Center(
        child: Text('No classified results yet for this division.'),
      );
    } else if (showingDrivers) {
      inner = RefreshIndicator(
        onRefresh: _loadRankingsAndDivisionData,
        child: ListView.builder(
          itemCount: _driverStandings.length,
          itemBuilder: (context, index) {
            final standing = _driverStandings[index];
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
              title: Text(standing.driverName),
              subtitle: Text(subtitle),
              onTap: () {
                final driver = _driversById[standing.driverId];
                if (driver == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Driver profile not available for this entry.'),
                    ),
                  );
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DriverProfilePage(
                      driver: driver,
                      division: widget.division,
                      eventRepository: widget.eventRepository,
                      sessionResultRepository:
                          widget.sessionResultRepository,
                      penaltyRepository: widget.penaltyRepository,
                      driverRepository: widget.driverRepository,
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    } else {
      inner = RefreshIndicator(
        onRefresh: _loadRankingsAndDivisionData,
        child: ListView.builder(
          itemCount: _teamStandings.length,
          itemBuilder: (context, index) {
            final standing = _teamStandings[index];
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
                      division: widget.division,
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
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(20),
            isSelected: [
              _rankingsTabIndex == 0,
              _rankingsTabIndex == 1,
            ],
            onPressed: (index) {
              setState(() {
                _rankingsTabIndex = index;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Drivers'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Constructors'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: inner),
      ],
    );
  }

  // ---------- Scaffold ----------

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_currentEventsTabIndex) {
      case 0:
        body = _buildRaceTab();
        break;
      case 1:
        body = _buildTeamsTab();
        break;
      case 2:
        body = _buildDriversTab();
        break;
      case 3:
      default:
        body = _buildRankingsTab();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Events – ${widget.division.name}'),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentEventsTabIndex,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentEventsTabIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: 'Race',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Teams',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Drivers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Rankings',
          ),
        ],
      ),
      floatingActionButton: _currentEventsTabIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddEventSheet,
              tooltip: 'Add event',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

