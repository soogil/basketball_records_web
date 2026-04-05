import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/record_add_presenter.dart';
import 'package:iggys_point/views/widgets/team_input_section.dart';

class RecordAddScreen extends HookConsumerWidget {
  const RecordAddScreen({
    super.key,
    required this.allPlayers,
  });

  final List<PlayerModel> allPlayers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePlayers = useState<List<PlayerModel>>(
      List.from(allPlayers)..sort((a, b) => a.name.compareTo(b.name)),
    );
    final teams = useState<List<List<PlayerGameInput>>>([[], []]);
    final teamMetas = useMemoized(() => [TeamMeta(), TeamMeta()], []);
    final selectedTeam = useState<int>(0);
    final isExistRecord = useState<bool>(false);
    final selectedDate = useState<DateTime?>(null);

    void bindTeamInputListeners(int teamIdx) {
      final meta = teamMetas[teamIdx];
      meta.gamesController.addListener(() {
        final games = meta.gamesController.text;
        for (var player in teams.value[teamIdx]) {
          player.totalGamesController.text = games;
        }
      });
      meta.winsController.addListener(() {
        final wins = meta.winsController.text;
        for (var player in teams.value[teamIdx]) {
          player.winGamesController.text = wins;
        }
      });
      meta.scoreController.addListener(() {
        final score = meta.scoreController.text;
        for (var player in teams.value[teamIdx]) {
          player.winScoreController.text = score;
        }
      });
    }

    useEffect(() {
      for (int i = 0; i < teamMetas.length; i++) {
        bindTeamInputListeners(i);
      }
      return () {
        for (var meta in teamMetas) {
          meta.dispose();
        }
      };
    }, []);

    String formattedDate(DateTime? date) => date == null
        ? ''
        : '${date.year}-${date.month.toString().padLeft(2, '0')}'
            '-${date.day.toString().padLeft(2, '0')}';

    void addTeam() {
      if (teams.value.length < 3) {
        teamMetas.add(TeamMeta());
        teams.value = [...teams.value, []];
        bindTeamInputListeners(teams.value.length - 1);
      }
    }

    void removeTeam(int idx) {
      final removedPlayers = teams.value[idx].map((e) => e.player);
      availablePlayers.value = [...availablePlayers.value, ...removedPlayers]
        ..sort((a, b) => a.name.compareTo(b.name));

      final newTeams = List<List<PlayerGameInput>>.from(teams.value);
      newTeams.removeAt(idx);
      teams.value = newTeams;

      teamMetas[idx].dispose();
      teamMetas.removeAt(idx);

      if (selectedTeam.value >= teams.value.length) {
        selectedTeam.value = 0;
      }
    }

    void movePlayerToTeam(PlayerModel player) {
      if (!availablePlayers.value.contains(player)) return;

      final newAvailable = List<PlayerModel>.from(availablePlayers.value);
      newAvailable.remove(player);
      availablePlayers.value = newAvailable;

      final playerInput = PlayerGameInput(player: player);
      final meta = teamMetas[selectedTeam.value];
      playerInput.totalGamesController.text = meta.gamesController.text;
      playerInput.winGamesController.text = meta.winsController.text;
      playerInput.winScoreController.text = meta.scoreController.text;

      final newTeams = List<List<PlayerGameInput>>.from(teams.value);
      newTeams[selectedTeam.value] = [
        ...newTeams[selectedTeam.value],
        playerInput
      ];
      teams.value = newTeams;
    }

    void removePlayerFromTeam(PlayerGameInput playerInput, int teamIdx) {
      final newTeams = List<List<PlayerGameInput>>.from(teams.value);
      newTeams[teamIdx] =
          List<PlayerGameInput>.from(newTeams[teamIdx])..remove(playerInput);
      teams.value = newTeams;

      availablePlayers.value = [
        ...availablePlayers.value,
        playerInput.player
      ]..sort((a, b) => a.name.compareTo(b.name));
    }

    Future<void> showDialogMessage(String message) {
      return showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.all(30),
          content: Text(message, style: const TextStyle(fontSize: 20)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }

    Future<bool> showConfirmDialog(String message) async {
      return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.all(30),
              content: Text(
                message,
                style: TextStyle(
                  fontSize:
                      22.0.responsiveFontSize(context, minFontSize: 16),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 17.0
                          .responsiveFontSize(context, minFontSize: 11),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 17.0
                          .responsiveFontSize(context, minFontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    Future<void> onSave() async {
      if (selectedDate.value == null) {
        showDialogMessage('날짜를 선택 하세요.');
        return;
      }
      if (isExistRecord.value) {
        showDialogMessage('해당 날짜에 기록이 있습니다.\n기록을 삭제하고 저장 해주세요.');
        return;
      }

      final teamInputs = List<TeamInput>.generate(
        teams.value.length,
        (i) => TeamInput(teamName: '팀 ${i + 1}', players: teams.value[i]),
      );

      await ref.read(recordAddPresenterProvider.notifier).saveRecords(
            selectedDate.value!,
            teamInputs,
            availablePlayers.value,
          );

      if (context.mounted) Navigator.pop(context);
    }

    Future<void> onRemove() async {
      if (selectedDate.value == null) return;

      final confirmed = await showConfirmDialog('정말 삭제 하시겠습니까?');
      if (!confirmed) return;

      final success = await ref
          .read(recordAddPresenterProvider.notifier)
          .removeRecordFromDate(selectedDate.value!);

      if (!success) return;

      isExistRecord.value = false;
      await showDialogMessage(
          '${formattedDate(selectedDate.value)} 기록이 삭제 됐습니다.');
    }

    return Scaffold(
      backgroundColor: BRColors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: BRColors.greenB2,
        title: Container(
          margin: const EdgeInsets.only(left: 30),
          width: 200,
          height: 50,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2025, 1, 1),
                lastDate: DateTime.now(),
              );

              if (date != null) {
                selectedDate.value = date;
                isExistRecord.value = await ref
                    .read(recordAddPresenterProvider.notifier)
                    .hasAnyRealRecordOnDate(formattedDate(date));
              }
            },
            child: Row(
              children: [
                Text(
                  selectedDate.value == null
                      ? '날짜를 선택 하세요.'
                      : formattedDate(selectedDate.value),
                  style: const TextStyle(color: BRColors.white, fontSize: 20),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.calendar_today,
                    color: BRColors.white, size: 25),
              ],
            ),
          ),
        ),
        actions: [
          if (selectedDate.value != null && isExistRecord.value)
            Container(
              margin: const EdgeInsets.only(right: 30),
              height: 50,
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: BRColors.greenCf),
                onPressed: onRemove,
                child: Text(
                  '${formattedDate(selectedDate.value)} 기록 삭제',
                  style: const TextStyle(fontSize: 15, color: BRColors.black),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < teams.value.length; i++)
                    Expanded(
                      child: TeamInputSection(
                        teamIndex: i,
                        team: teams.value[i],
                        meta: teamMetas[i],
                        isFirst: i == 0,
                        isLast: i == teams.value.length - 1,
                        isSelected: selectedTeam.value == i,
                        showDeleteButton:
                            teams.value.length == 3 && i == 2,
                        onTap: () => selectedTeam.value = i,
                        onRemoveTeam: () => removeTeam(i),
                        onRemovePlayer: (p) => removePlayerFromTeam(p, i),
                        onAttendanceChanged: () =>
                            teams.value = [...teams.value],
                      ),
                    ),
                  if (teams.value.length < 3)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: addTeam,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 5),
            const Text('아래에서 선수를 선택해 팀에 추가하세요'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availablePlayers.value
                  .map(
                    (player) => ActionChip(
                      backgroundColor: BRColors.greyDa,
                      label: Text(player.name),
                      onPressed: () => movePlayerToTeam(player),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: BRColors.greenCf),
                onPressed: onSave,
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 15, color: BRColors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
