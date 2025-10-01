import 'package:flutter/material.dart';
import 'package:forkball/game_model.dart';
import 'package:forkball/teams.dart';
import 'package:forkball/zugball_fields.dart';
import 'package:zugclient/zug_user.dart';

//TODO: squashedWidth
class MatchupWidget extends StatelessWidget {
  final GameModel model;
  final bool showHeader;
  const MatchupWidget(this.model,{this.showHeader = false,super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          if (showHeader) Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E3A8A).withOpacity(0.8),
                  const Color(0xFF3B82F6).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_baseball,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  "Game Matchup",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Teams Row
          Row(
            children: [
              Expanded(child: getPlayRow(ZugBallField.homeTeam, bc.maxHeight - 128, bc.maxHeight - 128)),
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "VS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              Expanded(child: getPlayRow(ZugBallField.awayTeam, bc.maxHeight - 128, bc.maxHeight - 128)),
            ],
          ),
        ],
      ),
    ));
  }

  Widget getPlayRow(String teamSide, double cardWidth, double cardHeight) {
    dynamic teamData = model.currentArea.upData[teamSide];
    final bool isHome = teamSide == ZugBallField.homeTeam;

    if (teamData != null) {
      Team? team = Team.getTeamFromAbbrev(teamData[ZugBallField.abbrev]);
      UniqueName mgrName = UniqueName.fromData(teamData[ZugBallField.manager]);
      Widget? teamImg = team?.getImage();

      // Calculate responsive sizes
      final imageSize = (cardWidth * 0.66).clamp(80.0, 480.0);
      final fontSize = (cardWidth / 20).clamp(12.0, 18.0);
      final headerFontSize = (cardWidth / 20).clamp(12.0, 16.0);

      return Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isHome
                  ? team?.color1 ?? const Color(0xFF065F46).withOpacity(0.1)
                  : team?.color1 ?? const Color(0xFF7C2D12).withOpacity(0.1),
              isHome
                  ? team?.color2 ?? const Color(0xFF065F46).withOpacity(0.05)
                  : team?.color2 ?? const Color(0xFF7C2D12).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHome
                ? const Color(0xFF10B981).withOpacity(0.3)
                : const Color(0xFFEA580C).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isHome
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFEA580C).withOpacity(0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/forksplash.gif'), // Add your pattern
                      fit: BoxFit.cover,
                      opacity: 0.03,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    getTeamImageContainer(teamImg,imageSize),
                    if (team != null) getTeamInfoWidget(team, isHome, fontSize),
                    getManagerSection(mgrName,isHome,headerFontSize),
                  ],
                ),
              ),

              // Subtle shine effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Empty state
    return getEmptyTeamWidget(cardWidth,cardHeight,isHome);
  }

  Widget getEmptyTeamWidget(double cardWidth, double cardHeight, bool isHome) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_baseball_outlined,
              size: (cardWidth * 0.2).clamp(32.0, 64.0),
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "Waiting for ${isHome ? 'Home' : 'Away'} Team",
              style: TextStyle(
                fontSize: (cardWidth / 20).clamp(10.0, 14.0),
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget getHomeAwayBadge(bool isHome, double headerFontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHome
            ? const Color(0xFF10B981)
            : const Color(0xFFEA580C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isHome
                ? const Color(0xFF10B981)
                : const Color(0xFFEA580C)).withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHome ? Icons.home : Icons.flight_takeoff,
            color: Colors.white,
            size: headerFontSize,
          ),
          const SizedBox(width: 6),
          Text(
            isHome ? "HOME" : "AWAY",
            style: TextStyle(
              color: Colors.white,
              fontSize: headerFontSize * 0.8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget getTeamImageContainer(Widget? teamImg, double imageSize) {
    return Expanded(
      flex: 4,
      child: Center(
        child: Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(0, -2),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipOval(
              child: teamImg ??
                  Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.sports_baseball,
                      size: imageSize * 0.4,
                      color: Colors.grey.shade600,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  getTeamInfoWidget(Team team, bool isHome, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "${team.city} ${team.name}",
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          //color: isHome ? const Color(0xFF065F46) : const Color(0xFF7C2D12),
          //backgroundColor: Colors.black,
          color: team.color1,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  getManagerSection(UniqueName mgrName, bool isHome, double headerFontSize) {
    return Expanded(
      flex: 1,
      child:
      Container(
          width: double.infinity,
          //height: 128,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            getHomeAwayBadge(isHome, headerFontSize),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: headerFontSize * 0.9,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "MANAGER",
                      style: TextStyle(
                        fontSize: headerFontSize * 0.7,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(child: UserWidget(uName: mgrName, height: 48,)), //, colorBlendMode: BlendMode.colorBurn)),
              ],
            )],
          )),
    );
  }

}