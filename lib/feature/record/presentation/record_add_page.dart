import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for TextInputFormatter
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/main/presentation/main_page.dart';
import 'package:iggys_point/feature/record/presentation/record_add_view_model.dart';

class RecordAddPage extends ConsumerStatefulWidget {
  const RecordAddPage({
    super.key,
    required this.allPlayers,
    required this.onSave,
    this.onRemove,
  });

  final List<PlayerModel> allPlayers;
  final Function(DateTime selectedDate, List<TeamInput>, List<PlayerModel>) onSave;
  final Function(DateTime date)? onRemove;

  @override
  ConsumerState<RecordAddPage> createState() => _RecordAddPageState();
}

class _RecordAddPageState extends ConsumerState<RecordAddPage> {
  late final List<PlayerModel> availablePlayers;
  final List<List<PlayerGameInput>> teams = [[], []];
  late final List<TeamMeta> teamMetas = [TeamMeta(), TeamMeta()];
  int _selectedTeam = 0;
  bool _isExistRecord = false;
  DateTime? _selectedDate;

  String get selectedDate => _selectedDate == null ? ''
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
          margin: EdgeInsets.only(left: 30),
          width: 200,
          height: 50,
          child: InkWell(
            onTap: () async {
              _selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2025, 1, 1),
                lastDate: DateTime.now(),);

              if (_selectedDate != null) {
                final viewModel = ref.read(
                    recordAddViewModelProvider.notifier);
                _isExistRecord = await viewModel.hasAnyRealRecordOnDate(selectedDate);
              }

              setState(() {});
            }, // DatePicker 함수 연결
            child: Row(
                children: [
                  Text(
                    _selectedDate == null
                        ? '날짜를 선택 하세요.'
                        : "${_selectedDate?.year}-${_selectedDate?.month
                        .toString().padLeft(2, '0')}-${_selectedDate?.day
                        .toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: BRColors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 5,),
                  Icon(Icons.calendar_today, color: BRColors.white, size: 25,)
                ]
            ),
          )
      ),
      actions: [
        if (_selectedDate != null && _isExistRecord) Container(
          margin: EdgeInsets.only(right: 30),
          height: 50,
          width: 200,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BRColors.greenCf,
            ),
            onPressed: () {
              if (_selectedDate != null && widget.onRemove != null) {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        contentPadding: EdgeInsets.all(30),
                        content: Text(
                          '정말 삭제 하시겠습니까?',
                          style: TextStyle(
                              fontSize: 22.0.responsiveFontSize(context, minFontSize: 16,),
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 17.0.responsiveFontSize(context, minFontSize: 11,),),
                              )),
                          ElevatedButton(
                              onPressed: () {
                                widget.onRemove!(_selectedDate!);
                                Navigator.pop(context);
                              },
                              child: Text(
                                '확인',
                                style: TextStyle(
                                  fontSize: 17.0.responsiveFontSize(context, minFontSize: 11,),
                                ),
                              )),
                        ],
                      );
                    }
                );
              }
            },
            child: Text(
              '$selectedDate 기록 삭제',
              style: TextStyle(
                  fontSize: 15,
                  color: BRColors.black
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10,),
          _teamView(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 5),
          Text("아래에서 선수를 선택해 팀에 추가하세요"),
          const SizedBox(height: 16),
          _playerChips(),
          SizedBox(height: 16),
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
                    bottomLeft: i == 0 ? Radius.circular(10) : Radius.zero,
                    topLeft: i == 0 ? Radius.circular(10) : Radius.zero,
                    bottomRight: i == teams.length - 1 ? Radius.circular(10) : Radius.zero,
                    topRight: i == teams.length - 1 ? Radius.circular(10) : Radius.zero,
                  ),
                ),
                onTap: () => selectTeam(i),
                tileColor: _selectedTeam == i ? BRColors.greenCf : BRColors.greyDa,
                title: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('팀 ${i + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 20),
                            Flexible(
                              child: TextField(
                                decoration: InputDecoration(labelText: "경기", isDense: true),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                controller: teamMetas[i].gamesController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: TextField(
                                decoration: InputDecoration(labelText: "승리", isDense: true),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                                ],
                                controller: teamMetas[i].winsController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: TextField(
                                decoration: InputDecoration(labelText: "승점", isDense: true),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                controller: teamMetas[i].scoreController,
                              ),
                            ),
                            if (teams.length == 3 && i == 2)
                              InkWell(
                                child: Icon(Icons.delete, color: BRColors.greenB2),
                                onTap: () => removeTeam(i),
                              )
                            // IconButton(
                            //   icon: Icon(Icons.delete, color: BRColors.greenB2),
                            //   onPressed: () => removeTeam(i),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          spacing: 8,
                          children: teams[i].map(
                                (playerInput) => _playerDetail(playerInput, i, onUpdate: () => setState(() {})),
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (teams.length < 3)
            IconButton(
              icon: Icon(Icons.add),
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
      children: availablePlayers.map(
            (player) =>
            ActionChip(
              backgroundColor: BRColors.greyDa,
              label: Text(player.name),
              onPressed: () => movePlayerToTeam(player),
            ),
      ).toList(),
    );
  }

  Widget _playerDetail(PlayerGameInput input, int index, {required VoidCallback onUpdate}) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(input.player.name, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 15),
            Flexible(
              child: DropdownButton<int>(
                value: input.attendanceScore,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 10, child: Text("참석")),
                  DropdownMenuItem(value: 5, child: Text("조퇴")),
                  DropdownMenuItem(value: -5, child: Text("노쇼")),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      input.attendanceScore = v;
                      if (v == -5) {
                        // 노쇼면 0으로 초기화
                        input.totalGamesController.text = '0';
                        input.winGamesController.text = '0';
                        input.winScoreController.text = '0';
                      } else {
                        // 팀 입력폼 따라감
                        final meta = teamMetas[index];
                        input.totalGamesController.text = meta.gamesController.text;
                        input.winGamesController.text = meta.winsController.text;
                        input.winScoreController.text = meta.scoreController.text;
                      }
                    });
                    onUpdate();
                  }
                },
                style: TextStyle(
                  fontSize: 14
                ),
                underline: SizedBox(),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextField(
                decoration: InputDecoration(labelText: '경기', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: input.totalGamesController,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: TextField(
                decoration: InputDecoration(labelText: '승리', isDense: true),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                ],
                controller: input.winGamesController,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: TextField(
                decoration: InputDecoration(labelText: '승점', isDense: true),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                controller: input.winScoreController,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              onPressed: () => removePlayerFromTeam(input, index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButtons() {
    return  SizedBox(
      height: 50,
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: BRColors.greenCf,
        ),
        onPressed: () {
          if (_isExistRecord) {
            showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.all(30),
                    content: Text(
                      '해당 날짜에 기록이 있습니다.\n기록을 삭제하고 저장 해주세요.',
                      style: TextStyle(
                          fontSize: 20
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            '확인',
                            style: TextStyle(),
                          )),
                    ],
                  );
                }
            );
          } else if (_selectedDate != null) {
            final teamInputs = List<TeamInput>.generate(
              teams.length,
                  (i) =>
                  TeamInput(
                    teamName: '팀 ${i + 1}',
                    players: teams[i],
                  ),
            );
            widget.onSave(_selectedDate!, teamInputs, availablePlayers);
          } else {
            showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.all(30),
                    content: Text(
                      '날짜를 선택 하세요.',
                      style: TextStyle(
                          fontSize: 20
                      ),
                    ),
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            '확인',
                            style: TextStyle(),
                          )),
                    ],
                  );
                }
            );
          }
        },
        child: Text(
          '저장',
          style: TextStyle(
              fontSize: 15,
              color: BRColors.black
          ),
        ),
      ),
    );
  }
}

class PlayerGameInput {
  final PlayerModel player;
  int attendanceScore;
  final TextEditingController totalGamesController;
  final TextEditingController winGamesController;
  final TextEditingController winScoreController;
  PlayerGameInput({
    required this.player,
    this.attendanceScore = 10,
  })  : totalGamesController = TextEditingController(text: '0'),
        winGamesController = TextEditingController(text: '0'),
        winScoreController = TextEditingController(text: '0');

  int get winScore => int.parse(winScoreController.text);
  int get winGames => int.parse(winGamesController.text);
  int get totalGames => int.parse(totalGamesController.text);
  String get playerId => player.id;

  @override
  String toString() {
    return '이름: ${player.name} 참석: $attendanceScore '
        '게임 수: ${totalGamesController.text} 승리: ${winGamesController.text} 승점: ${winScoreController.text}';
  }
}

// TeamInput 데이터 모델
class TeamInput {
  final String teamName;
  final List<PlayerGameInput> players;
  TeamInput({required this.teamName, required this.players});
}

class TeamMeta {
  final TextEditingController gamesController;
  final TextEditingController winsController;
  final TextEditingController scoreController;
  TeamMeta()
      : gamesController = TextEditingController(),
        winsController = TextEditingController(),
        scoreController = TextEditingController();

  void dispose() {
    gamesController.dispose();
    winsController.dispose();
    scoreController.dispose();
  }
}
