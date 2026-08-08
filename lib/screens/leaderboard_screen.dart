import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/sound_service.dart';
import '../l10n/app_strings.dart';
import 'settings_screen.dart';

class LeaderboardEntry {
  final String username;
  final String countryFlag;
  final String countryName;
  final int maxDepth;
  final int creaturesDecoded;
  final int medalsCount;
  final bool isUser;

  LeaderboardEntry({
    required this.username,
    required this.countryFlag,
    required this.countryName,
    required this.maxDepth,
    required this.creaturesDecoded,
    required this.medalsCount,
    this.isUser = false,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Depth, 1: Decoded, 2: Medals
  late SoundService _soundService;

  List<LeaderboardEntry> _generateDailyCompetitors() {
    final now = DateTime.now();
    // Unique seed based on calendar date (e.g. 20260807) to keep scores stable within the same day
    final int daySeed = now.year * 10000 + now.month * 100 + now.day;
    final random = math.Random(daySeed);

    final List<Map<String, dynamic>> baselines = [
      {'name': 'Captain Nemo', 'flag': '🇨🇦', 'country': 'Canada', 'baseDepth': 10500, 'baseDecoded': 18},
      {'name': 'Sakura', 'flag': '🇯🇵', 'country': 'Japan', 'baseDepth': 9500, 'baseDecoded': 17},
      {'name': 'Alex_Ocean', 'flag': '🇺🇸', 'country': 'USA', 'baseDepth': 8600, 'baseDecoded': 15},
      {'name': 'Hans_Sub', 'flag': '🇩🇪', 'country': 'Germany', 'baseDepth': 7800, 'baseDecoded': 14},
      {'name': 'Chloe_Abyss', 'flag': '🇫🇷', 'country': 'France', 'baseDepth': 7100, 'baseDecoded': 13},
      {'name': 'Arthur_Deep', 'flag': '🇬🇧', 'country': 'UK', 'baseDepth': 6500, 'baseDecoded': 12},
      {'name': 'Minh_Marine', 'flag': '🇻🇳', 'country': 'Vietnam', 'baseDepth': 5900, 'baseDecoded': 11},
      {'name': 'Igor_Diver', 'flag': '🇷🇺', 'country': 'Russia', 'baseDepth': 5200, 'baseDecoded': 10},
      {'name': 'Mateo_Trench', 'flag': '🇪🇸', 'country': 'Spain', 'baseDepth': 4400, 'baseDecoded': 9},
      {'name': 'Yuki_Sonar', 'flag': '🇯🇵', 'country': 'Japan', 'baseDepth': 3700, 'baseDecoded': 8},
      {'name': 'Lucas_Aqua', 'flag': '🇧🇷', 'country': 'Brazil', 'baseDepth': 3100, 'baseDecoded': 7},
      {'name': 'Liam_Deepsea', 'flag': '🇦🇺', 'country': 'Australia', 'baseDepth': 2600, 'baseDecoded': 6},
      {'name': 'Emma_Voyage', 'flag': '🇬🇧', 'country': 'UK', 'baseDepth': 1900, 'baseDecoded': 5},
      {'name': 'Jack_O2', 'flag': '🇺🇸', 'country': 'USA', 'baseDepth': 1300, 'baseDecoded': 3},
      {'name': 'Leo_Pressure', 'flag': '🇮🇹', 'country': 'Italy', 'baseDepth': 800, 'baseDecoded': 2},
    ];

    return baselines.map((data) {
      // Depth fluctuates by -200m to +500m based on the day
      final int depthDiff = -200 + random.nextInt(71) * 10;
      final int depth = (data['baseDepth'] as int) + depthDiff;

      // Decoded creatures fluctuate by -1 to +2
      int decoded = (data['baseDecoded'] as int) + (-1 + random.nextInt(4));
      if (decoded > 20) decoded = 20;
      if (decoded < 0) decoded = 0;

      // Calculate medals from their daily progress
      final int medals = _calculateUserMedals(depth, decoded, 20);

      return LeaderboardEntry(
        username: data['name'],
        countryFlag: data['flag'],
        countryName: data['country'],
        maxDepth: depth,
        creaturesDecoded: decoded,
        medalsCount: medals,
      );
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = Provider.of<SoundService>(context, listen: false);
  }

  int _calculateUserMedals(int bestDepth, int unlockedCreatures, int totalCreatures) {
    int count = 0;
    if (bestDepth >= 1000) count++;
    if (bestDepth >= 4000) count++;
    if (bestDepth >= 8000) count++;
    if (bestDepth >= 11000) count++;
    if (unlockedCreatures >= 10) count++;
    if (unlockedCreatures == totalCreatures) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context);
    final strings = AppStrings.listen(context);
    final bestDepth = dataService.highScoreDepth;
    final totalCreatures = dataService.creatures.length;
    final unlockedCreatures = dataService.creatures.where((c) => !c.isLocked).length;
    final userMedals = _calculateUserMedals(bestDepth, unlockedCreatures, totalCreatures);

    // Create entry for the current user
    final userEntry = LeaderboardEntry(
      username: strings.languageCode == 'vi' ? 'BẠN (THUYỀN TRƯỞNG)' : 'YOU (CAPTAIN)',
      countryFlag: '🇻🇳',
      countryName: 'Vietnam',
      maxDepth: bestDepth,
      creaturesDecoded: unlockedCreatures,
      medalsCount: userMedals,
      isUser: true,
    );

    // Combine and sort entries based on the active tab
    final List<LeaderboardEntry> combinedList = List.from(_generateDailyCompetitors())..add(userEntry);

    if (_activeTab == 0) {
      // Sort by depth
      combinedList.sort((a, b) => b.maxDepth.compareTo(a.maxDepth));
    } else if (_activeTab == 1) {
      // Sort by decoded creatures
      combinedList.sort((a, b) => b.creaturesDecoded.compareTo(a.creaturesDecoded));
    } else {
      // Sort by medals count
      combinedList.sort((a, b) => b.medalsCount.compareTo(a.medalsCount));
    }

    // Find user rank
    final userRank = combinedList.indexWhere((entry) => entry.isUser) + 1;

    return Scaffold(
      backgroundColor: const Color(0xFF010610),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F3D).withValues(alpha: 0.15),
        elevation: 0,
        title: Text(
          strings.languageCode == 'vi' ? 'BẢNG XẾP HẠNG TOÀN CẦU' : 'GLOBAL LEADERBOARD',
          style: const TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          buildVolumeButton(context),
          const SizedBox(width: 4),
          buildSettingsButton(context),
        ],
      ),
      body: Column(
        children: [
          // Submarine Cockpit grid line separator
          Container(
            width: double.infinity,
            height: 1.5,
            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
          ),

          // Apple Style Segmented Tab Control (Expanded to prevent overflow)
          Container(
            color: const Color(0xFF010610),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: _buildSegmentButton(0, strings.languageCode == 'vi' ? 'ĐỘ SÂU' : 'DEPTH')),
                const SizedBox(width: 4),
                Expanded(child: _buildSegmentButton(1, strings.languageCode == 'vi' ? 'GIẢI MÃ' : 'DECODED')),
                const SizedBox(width: 4),
                Expanded(child: _buildSegmentButton(2, strings.languageCode == 'vi' ? 'HUY CHƯƠNG' : 'MEDALS')),
              ],
            ),
          ),

          // List separator
          Container(
            width: double.infinity,
            height: 1.5,
            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
          ),

          // Competitors List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: combinedList.length,
              separatorBuilder: (context, index) => Container(
                height: 1.0,
                color: const Color(0xFF00F0FF).withValues(alpha: 0.08),
              ),
              itemBuilder: (context, index) {
                final entry = combinedList[index];
                final rank = index + 1;
                return _buildLeaderboardTile(entry, rank);
              },
            ),
          ),

          // Sticky User Rank Panel at bottom
          _buildUserStickyPanel(userEntry, userRank, totalCreatures),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        _soundService.playCreatureSound("click.mp3");
        setState(() {
          _activeTab = index;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF0D1F3D).withValues(alpha: 0.6) 
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: isActive ? const Color(0xFF00F0FF) : Colors.white.withValues(alpha: 0.1),
            width: isActive ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.zero, // Flat Apple-Console segmented control
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00F0FF) : Colors.white30,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry, int rank) {
    final bool isUser = entry.isUser;
    
    // Choose score text based on active tab
    String scoreText = '';
    if (_activeTab == 0) {
      scoreText = '${entry.maxDepth}m';
    } else if (_activeTab == 1) {
      scoreText = AppStrings.of(context).languageCode == 'vi' 
          ? '${entry.creaturesDecoded} loài' 
          : '${entry.creaturesDecoded} species';
    } else {
      scoreText = AppStrings.of(context).languageCode == 'vi'
          ? '${entry.medalsCount} huy chương'
          : '${entry.medalsCount} medals';
    }

    // Rank decoration
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = Image.asset(
        'assets/images/icon/award.png',
        width: 32,
        height: 32,
      );
    } else if (rank == 2) {
      rankWidget = Image.asset(
        'assets/images/icon/second-rank.png',
        width: 26,
        height: 26,
      );
    } else if (rank == 3) {
      rankWidget = Image.asset(
        'assets/images/icon/3rd-place.png',
        width: 26,
        height: 26,
      );
    } else {
      rankWidget = Text(
        '$rank',
        style: TextStyle(
          color: isUser ? const Color(0xFF00F0FF) : Colors.white30,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Container(
      color: isUser ? const Color(0xFF00F0FF).withValues(alpha: 0.05) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 1. Rank Position
          SizedBox(
            width: 38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: rankWidget,
            ),
          ),

          // 2. Country Flag Emoji
          Text(
            entry.countryFlag,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 14),

          // 3. Username & Country Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUser ? const Color(0xFF00F0FF) : Colors.white,
                    fontWeight: isUser ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.countryName.toUpperCase(),
                  style: TextStyle(
                    color: isUser ? const Color(0xFF00F0FF).withValues(alpha: 0.5) : Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // 4. Competitor Score
          Text(
            scoreText,
            style: TextStyle(
              color: isUser ? const Color(0xFF00F0FF) : (rank <= 3 ? Colors.amber : Colors.white70),
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStickyPanel(LeaderboardEntry userEntry, int rank, int totalCreatures) {
    final strings = AppStrings.of(context);
    final isEn = strings.languageCode == 'en';
    
    // Choose status description based on active tab
    String description = '';
    if (_activeTab == 0) {
      description = isEn
          ? 'Deepest simulator dive: ${userEntry.maxDepth}m'
          : 'Độ sâu mô phỏng kỷ lục: ${userEntry.maxDepth}m';
    } else if (_activeTab == 1) {
      description = isEn
          ? 'Decoded: ${userEntry.creaturesDecoded} / $totalCreatures species'
          : 'Giải mã: ${userEntry.creaturesDecoded} / $totalCreatures loài';
    } else {
      description = isEn
          ? 'Unlocked: ${userEntry.medalsCount} / 6 medals'
          : 'Mở khóa: ${userEntry.medalsCount} / 6 huy chương';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3D).withValues(alpha: 0.25),
        border: Border(
          top: BorderSide(color: const Color(0xFF00F0FF).withValues(alpha: 0.25), width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          // User Rank highlight bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1.0),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEn ? 'YOUR GLOBAL RANKING' : 'XẾP HẠNG CỦA BẠN',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Big Trophy Badge
          Image.asset(
            'assets/images/icon/award.png',
            width: 36,
            height: 36,
            color: const Color(0xFF00F0FF),
          ),
        ],
      ),
    );
  }
}

// Reusable Leaderboard button for other screens
Widget buildLeaderboardButton(BuildContext context) {
  return IconButton(
    icon: Image.asset(
      'assets/images/icon/award.png',
      width: 26,
      height: 26,
    ),
    tooltip: 'Leaderboard',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
      );
    },
  );
}
