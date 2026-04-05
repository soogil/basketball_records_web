import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/models/player_model.dart';

class TeamInputSection extends StatelessWidget {
  const TeamInputSection({
    super.key,
    required this.teamIndex,
    required this.team,
    required this.meta,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.showDeleteButton,
    required this.onTap,
    required this.onRemoveTeam,
    required this.onRemovePlayer,
    required this.onAttendanceChanged,
  });

  final int teamIndex;
  final List<PlayerGameInput> team;
  final TeamMeta meta;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final bool showDeleteButton;
  final VoidCallback onTap;
  final VoidCallback onRemoveTeam;
  final void Function(PlayerGameInput) onRemovePlayer;
  final VoidCallback onAttendanceChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft:
              isFirst ? const Radius.circular(10) : Radius.zero,
          topLeft:
              isFirst ? const Radius.circular(10) : Radius.zero,
          bottomRight:
              isLast ? const Radius.circular(10) : Radius.zero,
          topRight:
              isLast ? const Radius.circular(10) : Radius.zero,
        ),
      ),
      onTap: onTap,
      tileColor: isSelected ? BRColors.greenCf : BRColors.greyDa,
      title: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '팀 ${teamIndex + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: '경기', isDense: true),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      controller: meta.gamesController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: '승리', isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}$')),
                      ],
                      controller: meta.winsController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: '승점', isDense: true),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      controller: meta.scoreController,
                    ),
                  ),
                  if (showDeleteButton)
                    InkWell(
                      onTap: onRemoveTeam,
                      child:
                          Icon(Icons.delete, color: BRColors.greenB2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                spacing: 8,
                children: team
                    .map(
                      (playerInput) => PlayerGameInputCard(
                        playerInput: playerInput,
                        meta: meta,
                        onRemove: () => onRemovePlayer(playerInput),
                        onAttendanceChanged: onAttendanceChanged,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerGameInputCard extends StatelessWidget {
  const PlayerGameInputCard({
    super.key,
    required this.playerInput,
    required this.meta,
    required this.onRemove,
    required this.onAttendanceChanged,
  });

  final PlayerGameInput playerInput;
  final TeamMeta meta;
  final VoidCallback onRemove;
  final VoidCallback onAttendanceChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerInput.player.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 15),
          Flexible(
            child: DropdownButton<int>(
              value: playerInput.attendanceScore,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 15, child: Text('참석')),
                DropdownMenuItem(value: 10, child: Text('조퇴')),
                DropdownMenuItem(value: -5, child: Text('노쇼')),
              ],
              onChanged: (v) {
                if (v != null) {
                  playerInput.attendanceScore = v;
                  if (v == -5) {
                    playerInput.totalGamesController.text = '0';
                    playerInput.winGamesController.text = '0';
                    playerInput.winScoreController.text = '0';
                  } else {
                    playerInput.totalGamesController.text =
                        meta.gamesController.text;
                    playerInput.winGamesController.text =
                        meta.winsController.text;
                    playerInput.winScoreController.text =
                        meta.scoreController.text;
                  }
                  onAttendanceChanged();
                }
              },
              style: const TextStyle(fontSize: 14),
              underline: const SizedBox(),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: TextField(
              decoration:
                  const InputDecoration(labelText: '경기', isDense: true),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: playerInput.totalGamesController,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TextField(
              decoration:
                  const InputDecoration(labelText: '승리', isDense: true),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}$')),
              ],
              controller: playerInput.winGamesController,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TextField(
              decoration:
                  const InputDecoration(labelText: '승점', isDense: true),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              controller: playerInput.winScoreController,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
