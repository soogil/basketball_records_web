import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/record_add_presenter.dart';

class RecordAddScreen extends ConsumerStatefulWidget {
  const RecordAddScreen({
    super.key,
    required this.allPlayers,
  });

  final List<PlayerModel> allPlayers;

  @override
  ConsumerState<RecordAddScreen> createState() => _RecordAddScreenState();
}

class _RecordAddScreenState extends ConsumerState<RecordAddScreen> {
  late final List<PlayerModel> availablePlayers;
  final List<List<PlayerGameInput>> teams = [[], []];
  late final List<TeamMeta> teamMetas = [TeamMeta(), TeamMeta()];
  int _selectedTeam = 0;
  bool _isExistRecord = false;
  DateTime? _selectedDate;

  String get _formattedDate => _selectedDate == null
      ? ''
      : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}'
          '-${_selectedDate!.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    availablePlayers = List.from(widget.allPlayers)
      ..sort((a, b) => a.name.compareTo(b.name));

    for (int i = 0; i < teamMetas.length; i++) {
      _bindTeamInputListeners(i);
    }
  }

  void addTeam() {
    if (teams.length < 3) {
      setState(() {
        teams.add([]);
        teamMetas.add(TeamMeta());
        _bindTeamInputListeners(teams.length - 1);
      });
    }
  }

  void removeTeam(int idx) {
    setState(() {
      availablePlayers.addAll(teams[idx].map((e) => e.player));
      teams.removeAt(idx);
      teamMetas[idx].dispose();
      teamMetas.removeAt(idx);
      if (_selectedTeam >= teams.length) _selectedTeam = 0;
      availablePlayers.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void selectTeam(int idx) {
    setState(() {
      _selectedTeam = idx;
    });
  }

  void movePlayerToTeam(PlayerModel player) {
    if (!availablePlayers.contains(player)) return;
    setState(() {
      availablePlayers.remove(player);
      final playerInput = PlayerGameInput(player: player);
      final meta = teamMetas[_selectedTeam];
      playerInput.totalGamesController.text = meta.gamesController.text;
      playerInput.winGamesController.text = meta.winsController.text;
      playerInput.winScoreController.text = meta.scoreController.text;
      teams[_selectedTeam].add(playerInput);
    });
  }

  void removePlayerFromTeam(PlayerGameInput playerInput, int teamIdx) {
    setState(() {
      teams[teamIdx].remove(playerInput);
      availablePlayers.add(playerInput.player);
      availablePlayers.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _bindTeamInputListeners(int teamIdx) {
    final meta = teamMetas[teamIdx];

    meta.gamesController.addListener(() {
      final games = meta.gamesController.text;
      for (var player in teams[teamIdx]) {
        player.totalGamesController.text = games;
      }
    });
    meta.winsController.addListener(() {
      final wins = meta.winsController.text;
      for (var player in teams[teamIdx]) {
        player.winGamesController.text = wins;
      }
    });
    meta.scoreController.addListener(() {
      final score = meta.scoreController.text;
      for (var player in teams[teamIdx]) {
        player.winScoreController.text = score;
      }
    });
  }

  Future<void> _onSave() async {
    if (_selectedDate == null) {
      _showDialog('날짜를 선택 하세요.');
      return;
    }
    if (_isExistRecord) {
      _showDialog('해당 날짜에 기록이 있습니다.\n기록을 삭제하고 저장 해주세요.');
      return;
    }

    final teamInputs = List<TeamInput>.generate(
      teams.length,
      (i) => TeamInput(teamName: '팀 ${i + 1}', players: teams[i]),
    );

    await ref.read(recordAddPresenterProvider.notifier).saveRecords(
          _selectedDate!,
          teamInputs,
          availablePlayers,
        );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _onRemove() async {
    if (_selectedDate == null) return;

    final confirmed = await _showConfirmDialog('정말 삭제 하시겠습니까?');
    if (!confirmed) return;

    final success = await ref
        .read(recordAddPresenterProvider.notifier)
        .removeRecordFromDate(_selectedDate!);

    if (!success || !mounted) return;

    setState(() {
      _isExistRecord = false;
    });

    await _showDialog('$_formattedDate 기록이 삭제 됐습니다.');
  }

  Future<void> _showDialog(String message) {
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

  Future<bool> _showConfirmDialog(String message) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BRColors.white,
      appBar: _appBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: BRColors.greenB2,
      title: Container(
        margin: const EdgeInsets.only(left: 30),
        width: 200,
        height: 50,
        child: InkWell(
          onTap: () async {
            _selectedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2025, 1, 1),
              lastDate: DateTime.now(),
            );

            if (_selectedDate != null) {
              _isExistRecord = await ref
                  .read(recordAddPresenterProvider.notifier)
                  .hasAnyRealRecordOnDate(_formattedDate);
            }

            setState(() {});
          },
          child: Row(
            children: [
              Text(
                _selectedDate == null ? '날짜를 선택 하세요.' : _formattedDate,
                style: const TextStyle(color: BRColors.white, fontSize: 20),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.calendar_today, color: BRColors.white, size: 25),
            ],
          ),
        ),
      ),
      actions: [
        if (_selectedDate != null && _isExistRecord)
          Container(
            margin: const EdgeInsets.only(right: 30),
            height: 50,
            width: 200,
            child: ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: BRColors.greenCf),
              onPressed: _onRemove,
              child: Text(
                '$_formattedDate 기록 삭제',
                style: const TextStyle(fontSize: 15, color: BRColors.black),
              ),
            ),
          ),
      ],
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          _teamView(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 5),
          const Text('아래에서 선수를 선택해 팀에 추가하세요'),
          const SizedBox(height: 16),
          _playerChips(),
          const SizedBox(height: 16),
          _bottomButtons(),
        ],
      ),
    );
  }

  Widget _teamView() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < teams.length; i++)
            Expanded(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft:
                        i == 0 ? const Radius.circular(10) : Radius.zero,
                    topLeft:
                        i == 0 ? const Radius.circular(10) : Radius.zero,
                    bottomRight: i == teams.length - 1
                        ? const Radius.circular(10)
                        : Radius.zero,
                    topRight: i == teams.length - 1
                        ? const Radius.circular(10)
                        : Radius.zero,
                  ),
                ),
                onTap: () => selectTeam(i),
                tileColor:
                    _selectedTeam == i ? BRColors.greenCf : BRColors.greyDa,
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
                            if (teams.length == 3 && i == 2)
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
                          children: teams[i]
                              .map((playerInput) => _playerDetail(
                                    playerInput,
                                    i,
                                    onUpdate: () => setState(() {}),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (teams.length < 3)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: addTeam,
            ),
        ],
      ),
    );
  }

  Widget _playerChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availablePlayers
          .map(
            (player) => ActionChip(
              backgroundColor: BRColors.greyDa,
              label: Text(player.name),
              onPressed: () => movePlayerToTeam(player),
            ),
          )
          .toList(),
    );
  }

  Widget _playerDetail(
    PlayerGameInput input,
    int index, {
    required VoidCallback onUpdate,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
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
            Text(input.player.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 15),
            Flexible(
              child: DropdownButton<int>(
                value: input.attendanceScore,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('참석')),
                  DropdownMenuItem(value: 10, child: Text('조퇴')),
                  DropdownMenuItem(value: -5, child: Text('노쇼')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      input.attendanceScore = v;
                      if (v == -5) {
                        input.totalGamesController.text = '0';
                        input.winGamesController.text = '0';
                        input.winScoreController.text = '0';
                      } else {
                        final meta = teamMetas[index];
                        input.totalGamesController.text =
                            meta.gamesController.text;
                        input.winGamesController.text =
                            meta.winsController.text;
                        input.winScoreController.text =
                            meta.scoreController.text;
                      }
                    });
                    onUpdate();
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
                controller: input.totalGamesController,
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
                controller: input.winGamesController,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: TextField(
                decoration:
                    const InputDecoration(labelText: '승점', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: input.winScoreController,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              onPressed: () => removePlayerFromTeam(input, index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return SizedBox(
      height: 50,
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: BRColors.greenCf),
        onPressed: _onSave,
        child: const Text(
          '저장',
          style: TextStyle(fontSize: 15, color: BRColors.black),
        ),
      ),
    );
  }
}
