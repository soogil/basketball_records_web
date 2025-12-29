import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/main/presentation/main_view_model.dart';
import 'package:iggys_point/feature/record/presentation/record_add_page.dart';
// import 'package:data_table_2/data_table_2.dart' show ColumnSize, DataColumn2, DataRow2, DataTable2;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;


final _tapCountProvider = StateProvider<int>((ref) => 0);
final isMobileProvider = Provider.family<bool, BuildContext>((ref, context) {
  return MediaQuery.of(context).size.width < 600;
});


class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  Future<void> deleteAllCookies() async {
    final cookies = web.document.cookie.split(';');
    for (var cookie in cookies) {
      final eqPos = cookie.indexOf('=');
      final name = eqPos > -1 ? cookie.substring(0, eqPos) : cookie;
      web.document.cookie =
      '$name=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/';
    }
    web.window.location.reload();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainViewModel = ref.watch(mainViewModelProvider);

    return RefreshIndicator(
      onRefresh: deleteAllCookies,
      child: mainViewModel.when(
        data: (data) {
          return Scaffold(
            body: _recordView(context, ref, data),
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () {
            //     final viewmodel = ref.read(playerListViewModelProvider.notifier);
            //
            //     viewmodel.uploadPlayers();
            //   },
            //   child: const Icon(Icons.refresh),
            // ),
          );
          // return _playerList(data.players);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('에러 발생: $error')),
      )
    );
  }

  SliverAppBar _appBar(BuildContext context, WidgetRef ref, PlayerListState state,) {
    final int tapCount = ref.watch(_tapCountProvider);
    final bool isMobile = ref.watch(isMobileProvider(context));

    final String selectedSeason = ref.watch(selectedSeasonProvider);

    return SliverAppBar(
      toolbarHeight: 70,
      backgroundColor: BRColors.greenB2,
      centerTitle: true,
      title: PopupMenuButton<String>(
      onSelected: (String season) {
        ref.read(selectedSeasonProvider.notifier).state = season;
      },
      // 버튼 모양 (텍스트 + 아이콘)
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '이기스 포인트 $selectedSeason', // 예: "2026 시즌"
            style: TextStyle(
                fontSize: 24.0.responsiveFontSize(context, minFontSize: 18),
                color: BRColors.white,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
      // 드롭다운 메뉴 아이템들
        itemBuilder: (BuildContext context) {
          return state.seasons.map((season) {
            late String currentYear;
            final isCurrentYear = season.isEmpty;

            if (isCurrentYear) {
              DateTime now = DateTime.now();

              int year = now.year;

              currentYear = year.toString();
            } else {
              currentYear = season;
            }

            return PopupMenuItem<String>(
              value: season,
              child: Text(
                '이기스 포인트 $currentYear',
              ),
            );
          }).toList();
        },
            ),
      // 초기화 및 시즌 리셋
      // leading: TextButton(
      //   onPressed: () async {
      //     await ref.read(mainViewModelProvider.notifier).archiveAndResetSeason();
      //   },
      //   child: Text("2025 마감 실행(조심!)", style: TextStyle(color: Colors.red)),
      // ),
      // 관리자용 기록추가 버튼
      leading: GestureDetector(
        child: Container(
          color: Colors.transparent,
          width: 50,
          height: 50,
        ),
        onTap: () {
          if (!isMobile) {
            ref.read(_tapCountProvider.notifier).state++;
          }
        },
      ),
      actions: tapCount < 7 ? [] :[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white)),
          onPressed: () async {
            final String? name = await showPlayerNameDialog(context);

            if (name?.isNotEmpty ?? false) {
              final mainViewModel = ref.read(mainViewModelProvider.notifier);
              await mainViewModel.addPlayer(name!);
              ref.invalidate(mainViewModelProvider);
            }
          },
          child: Text(
            '선수 추가',
            style: TextStyle(
                fontSize: 15.0.responsiveFontSize(context, minFontSize: 12),
                color: Colors.white
            ),
          ),
        ),
        SizedBox(width: 10.0.responsiveFontSize(context, minFontSize: 8),),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white)),
            onPressed: () {
              final players = ref.read(mainViewModelProvider).value?.players ?? [];

              onSave(DateTime dateTime, List<TeamInput> teams,
                  List<PlayerModel> nonAttendantPlayers, bool isDouble) async {
                final viewModel = ref.read(mainViewModelProvider.notifier);
                final List<PlayerGameInput> playerInputs = teams
                    .expand((team) => team.players)
                    .toList();

                if (isDouble) {
                  for (PlayerGameInput playerInput in playerInputs) {
                    if (playerInput.attendanceScore > 0) {
                      playerInput.attendanceScore *= 2;
                    }
                    playerInput.winScoreController.text = '${playerInput.winScore * 2}';

                    // print('${playerInput.playerName} '
                    //     '${playerInput.attendanceScore} ${playerInput.winScore}');
                  }
                }

                final List<PlayerGameInput> absentInputs = nonAttendantPlayers
                    .map((player) => PlayerGameInput(
                  player: player,
                  attendanceScore: 0,
                )).toList();

                final List<PlayerGameInput> allPlayers = [
                  ...playerInputs,
                  ...absentInputs
                ];

                await viewModel.savePlayerRecords(
                    recordDate: '${dateTime.year}-'
                        '${dateTime.month.toString().padLeft(2, '0')}'
                        '-${dateTime.day.toString().padLeft(2, '0')}',
                    playerInputs: allPlayers,);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }

              onRemove(DateTime dateTime) async {
                final String date = '${dateTime.year}-'
                    '${dateTime.month.toString().padLeft(2, '0')}'
                    '-${dateTime.day.toString().padLeft(2, '0')}';

                final mainViewModel = ref.read(mainViewModelProvider.notifier);

                final bool result = await mainViewModel.removeRecordFromDate(date);

                if (result) {
                  if (context.mounted) {
                    showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            contentPadding: EdgeInsets.all(30),
                            content: Text(
                              '$date 기록이 삭제 됐습니다.',
                              style: TextStyle(
                                  fontSize: 20
                              ),
                            ),
                            actions: [
                              ElevatedButton(
                                  onPressed: () {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text('완료'))
                            ],
                          );
                        });
                  }
                }
              }

            context.pushNamed(AppPage.recordAdd.name, extra: {
              'onSave': onSave,
              'onRemove': onRemove,
              'allPlayers': players
              }).then((_) {
                ref.invalidate(mainViewModelProvider);
              });
            },
            child: Text(
              '기록 추가',
              style: TextStyle(
                  fontSize: 15.0.responsiveFontSize(context, minFontSize: 12),
                  color: Colors.white
              ),
            )
        ),
        const SizedBox(width: 50,),
      ],
    );
  }

  Future<String?> showPlayerNameDialog(BuildContext context) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('선수 이름 입력'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '이름을 입력하세요'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 취소
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name); // 입력값 반환
                }
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _recordView(BuildContext context, WidgetRef ref, PlayerListState state) {
    return CustomScrollView(
      slivers: [
        _appBar(context, ref, state),
        SliverStickyHeader(
          header: _buildHeader(context, ref),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final player = state.players[index];
                return _buildTableRow(context, ref, player, index);
              },
              childCount: state.players.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(mainViewModelProvider.notifier);

    return Row(
      children: PlayerColumn.values.map((col) {
        final isSorted = viewModel.sortColumn == col;
        final isRank = col == PlayerColumn.rank;

        return Expanded(
          flex: col.flex,
          child: Container(
            color: BRColors.greenCf,
            height: 50,
            child: isRank
                ? Center(
              child: Text(
                col.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0.responsiveFontSize(context, minFontSize: 12),
                ),
              ),
            )
                : InkWell(
              onTap: () => viewModel.sortPlayersOnTable(col),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    col.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0.responsiveFontSize(context, minFontSize: 12),
                    ),
                  ),
                  if (isSorted)
                    Row(
                      children: [
                        const SizedBox(width: 2),
                        Icon(
                          viewModel.sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 20.0.responsiveFontSize(context, minFontSize: 13),
                          color: Colors.black,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 데이터 Row
  Widget _buildTableRow(BuildContext context, WidgetRef ref, PlayerModel player, int index) {
    final bool isCurrentSeason = ref.watch(isCurrentSeasonProvider);
    final bool isEven = index.isEven;

    return ListTile(
      contentPadding: EdgeInsets.all(0),
        minTileHeight: 50,
        onTap: () => context.pushNamed(AppPage.playerDetail.name, extra: {
          'playerId': player.id,
          'playerName': player.name,
        }).then((refresh) {
          if ((refresh as bool?) ?? false) {
            ref.invalidate(mainViewModelProvider);
          }
        }),
        tileColor: isEven ? BRColors.greyDa : BRColors.whiteE8,
        title: Row(
            mainAxisSize: MainAxisSize.max,
            children: PlayerColumn.values
                .map((col) => Expanded(
                    flex: col.flex,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.valueByColumn(col, index: index + 1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: col == PlayerColumn.accumulatedScore
                                ? player.accumulatedScoreColor
                                : BRColors.black,
                            fontWeight: col == PlayerColumn.accumulatedScore
                                ? FontWeight.bold
                                : FontWeight.normal ,
                            fontSize: 18.0.responsiveFontSize(context, minFontSize: 13),
                          ),
                        ),
                        if (col == PlayerColumn.accumulatedScore && player.scoreAchieved && isCurrentSeason)
                          Row(
                            children: [
                              const SizedBox(width: 5),
                              Icon(Icons.emoji_events, color: Colors.amber,),
                          ],
                        )
                      ],
                    )))
                .toList()
        ));
  }
}

extension ResponsiveFontSize on double {
  double responsiveFontSize(BuildContext context, {double? minFontSize}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600 && minFontSize != null) {
      return minFontSize;
    }
    return this;
  }
}
