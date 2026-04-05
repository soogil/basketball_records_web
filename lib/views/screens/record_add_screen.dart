import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/record_add_presenter.dart';

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
        final newMeta = TeamMeta();
        teamMetas.add(newMeta);
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
      newTeams[selectedTeam.value] = [...newTeams[selectedTeam.value], playerInput];
      teams.value = newTeams;
    }

    void removePlayerFromTeam(PlayerGameInput playerInput, int teamIdx) {
      final newTeams = List<List<PlayerGameInput>>.from(teams.value);
      newTeams[teamIdx] = List<PlayerGameInput>.from(newTeams[teamIdx])..remove(playerInput);
      teams.value = newTeams;

      availablePlayers.value = [...availablePlayers.value, playerInput.player]
        ..sort((a, b) => a.name.compareTo(b.name));
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
                  fontSize: 22.0.responsiveFontSize(context, minFontSize: 16),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize:
                          17.0.responsiveFontSize(context, minFontSize: 11),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize:
                          17.0.responsiveFontSize(context, minFontSize: 11),
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
      await showDialogMessage('${formattedDate(selectedDate.value)} 기록이 삭제 됐습니다.');
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
                  selectedDate.value == null ? '날짜를 선택 하세요.' : formattedDate(selectedDate.value),
                  style: const TextStyle(color: BRColors.white, fontSize: 20),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.calendar_today, color: BRColors.white, size: 25),
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
                style:
                    ElevatedButton.styleFrom(backgroundColor: BRColors.greenCf),
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
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft:
                                i == 0 ? const Radius.circular(10) : Radius.zero,
                            topLeft:
                                i == 0 ? const Radius.circular(10) : Radius.zero,
                            bottomRight: i == teams.value.length - 1
                                ? const Radius.circular(10)
                                : Radius.zero,
                            topRight: i == teams.value.length - 1
                                ? const Radius.circular(10)
                                : Radius.zero,
                          ),
                        ),
                        onTap: () => selectedTeam.value = i,
                        tileColor:
                            selectedTeam.value == i ? BRColors.greenCf : BRColors.greyDa,
                        title: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('팀 ${i + 1}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 20),
                                    Flexible(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: '경기', isDense: true),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        controller: teamMetas[i].gamesController,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: '승리', isDense: true),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}$')),
                                        ],
                                        controller: teamMetas[i].winsController,
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
                                        controller: teamMetas[i].scoreController,
                                      ),
                                    ),
                                    if (teams.value.length == 3 && i == 2)
                                      InkWell(
                                        child: Icon(Icons.delete,
                                            color: BRColors.greenB2),
                                        onTap: () => removeTeam(i),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  spacing: 8,
                                  children: teams.value[i]
                                      .map((playerInput) => Container(
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
                                                Text(playerInput.player.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                                          final meta = teamMetas[i];
                                                          playerInput.totalGamesController.text =
                                                              meta.gamesController.text;
                                                          playerInput.winGamesController.text =
                                                              meta.winsController.text;
                                                          playerInput.winScoreController.text =
                                                              meta.scoreController.text;
                                                        }
                                                        teams.value = [...teams.value];
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
                                                  onPressed: () => removePlayerFromTeam(playerInput, i),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                style: ElevatedButton.styleFrom(backgroundColor: BRColors.greenCf),
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
