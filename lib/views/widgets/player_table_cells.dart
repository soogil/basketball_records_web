import 'package:flutter/material.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/player_model.dart';

enum ScoreDisplayMode { tierBadge, progressBar }

class PlayerAccumulatedCell extends StatelessWidget {
  const PlayerAccumulatedCell({
    super.key,
    required this.player,
    required this.isCurrentSeason,
    this.mode = ScoreDisplayMode.progressBar,
  });

  final PlayerModel player;
  final bool isCurrentSeason;
  final ScoreDisplayMode mode;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ScoreDisplayMode.tierBadge:
        return _TierBadgeCell(player: player, isCurrentSeason: isCurrentSeason);
      case ScoreDisplayMode.progressBar:
        return _ProgressBarCell(player: player, isCurrentSeason: isCurrentSeason);
    }
  }
}

class _TierBadgeCell extends StatelessWidget {
  const _TierBadgeCell({required this.player, required this.isCurrentSeason});
  final PlayerModel player;
  final bool isCurrentSeason;

  @override
  Widget build(BuildContext context) {
    final tier = player.tier;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${player.accumulatedScore}점',
              style: TextStyle(
                fontSize: 16.0.responsiveFontSize(context, minFontSize: 12),
                fontWeight: FontWeight.bold,
                color: tier?.badgeColor ?? BRColors.black,
              ),
            ),
            if (player.scoreAchieved && isCurrentSeason) ...[
              const SizedBox(width: 3),
              const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
            ],
          ],
        ),
        if (tier != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: tier.badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tier.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.0.responsiveFontSize(context, minFontSize: 8),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressBarCell extends StatelessWidget {
  const _ProgressBarCell({required this.player, required this.isCurrentSeason});
  final PlayerModel player;
  final bool isCurrentSeason;

  @override
  Widget build(BuildContext context) {
    final barColor = player.progressBarColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${player.accumulatedScore}',
                style: TextStyle(
                  fontSize: 14.0.responsiveFontSize(context, minFontSize: 11),
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
              Text(
                ' / ${player.nextMilestone}',
                style: TextStyle(
                  fontSize: 11.0.responsiveFontSize(context, minFontSize: 9),
                  color: Colors.grey.shade600,
                ),
              ),
              if (player.scoreAchieved && isCurrentSeason) ...[
                const SizedBox(width: 3),
                const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * player.milestoneProgress,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
