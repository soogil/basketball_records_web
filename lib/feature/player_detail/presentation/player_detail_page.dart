import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/feature/record/data/models/record_model.dart';
import 'package:iggys_point/feature/main/presentation/main_page.dart';
import 'package:iggys_point/feature/player_detail/presentation/player_detail_record_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';


final _tapCountProvider = StateProvider<int>((ref) => 0);

class PlayerDetailPage extends ConsumerWidget {
  const PlayerDetailPage({super.key,
    required this.playerId,
    required this.playerName,
  });

  final String playerId;
  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsState = ref.watch(playerDetailRecordViewModelProvider(playerId));

    return Scaffold(
      appBar: _appBar(context, ref),
      body: recordsState.when(
          data: (data) => _body(context, data, ref),
          error: (_, e) => Text(e.toString()),
          loading: () => Center(child: CircularProgressIndicator(
            color: BRColors.greyDa,
          ))),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, WidgetRef ref) {
    final tapCount = ref.watch(_tapCountProvider);
    final isMobile = ref.watch(isMobileProvider(context));

    return AppBar(
      toolbarHeight: 70,
      centerTitle: true,
      backgroundColor: BRColors.greenB2,
      title: GestureDetector(
        onTap: () {
          if (!isMobile) {
            ref.read(_tapCountProvider.notifier).state++;
          }
        },
        child: Text(
          '$playerName 기록',
          style: TextStyle(
              fontSize: 24.0.responsiveFontSize(context, minFontSize: 18),
              color: BRColors.white
          ),
        ),
      ),
      actions: tapCount < 7 ? [] :[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white)),
          onPressed: () async {
            final bool? confirm = await _showRemovePlayerDialog(context);

            if (confirm ?? false) {
              final recordsState = ref.read(playerDetailRecordViewModelProvider(playerId).notifier);
              await recordsState.removePlayer(playerId);

              if (context.mounted) {
                Navigator.pop(context, true);
              }
            }
          },
          child: Text(
            '선수 삭제',
            style: TextStyle(
                fontSize: 15.0.responsiveFontSize(context, minFontSize: 12),
                color: Colors.white
            ),
          ),
        ),
        const SizedBox(width: 50,),
      ],
    );
  }

  Future<bool?> _showRemovePlayerDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(
            '정말 삭제하시겠습니까?',
            style: TextStyle(
              fontSize: 19.0.responsiveFontSize(context, minFontSize: 15),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '취소',
                style: TextStyle(
                  fontSize: 15.0.responsiveFontSize(context, minFontSize: 12,),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize: 15.0.responsiveFontSize(context, minFontSize: 12,),
                ),),
            ),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, DateRecords state, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverStickyHeader(
                header: _buildHeader(context, ref),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final record = state.records[index];
                      return _buildTableRow(record, index, context);
                    },
                    childCount: state.records.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        _totalState(context, state.records),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: PlayerRecordColumn.values.map((col) {
        // final isSorted = viewModel.sortColumn == col;
        return Expanded(
          flex: col.flex,
          child: Container(
            color: BRColors.greenCf,
            height: 50,
            child: InkWell(
              // onTap: () => viewModel.sortPlayersOnTable(col),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(col.label,
                    style: TextStyle(
                      fontSize: 16.0.responsiveFontSize(context, minFontSize: 12),
                    ),),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 데이터 Row
  Widget _buildTableRow(RecordModel record, int index, BuildContext context) {
    final isEven = index.isEven;

    return ListTile(
        contentPadding: EdgeInsets.all(0),
        minTileHeight: 50,
        // onTap: () {
        //   context.pushNamed(AppPage.playerDetail.path, extra: record.id);
        // },
        tileColor: isEven ? BRColors.greyDa : BRColors.whiteE8,
        title: Row(
            mainAxisSize: MainAxisSize.max,
            children: PlayerRecordColumn.values
                .map((col) =>
                Expanded(
                    flex: col.flex,
                    child: Text(
                      record.valueByColumn(col),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.0.responsiveFontSize(context, minFontSize: 15),
                      ),
                    )))
                .toList()
        ));
  }

  Widget _totalState(BuildContext context, List<RecordModel> records) {
    // 각 컬럼별 합계 계산
    Map<PlayerRecordColumn, num> totals = {};
    for (final col in PlayerRecordColumn.values) {
      num sum;
      switch (col) {
        case PlayerRecordColumn.attendanceScore:
          sum = records.fold<int>(0, (prev, r) => prev + r.attendanceScore);
          break;
        case PlayerRecordColumn.winScore:
          sum = records.fold<int>(0, (prev, r) => prev + r.winScore);
          break;
        case PlayerRecordColumn.winningGames:
          sum = records.fold<double>(0.0, (prev, r) => prev + r.winningGames);
          break;
        case PlayerRecordColumn.totalGames:
          sum = records.fold<int>(0, (prev, r) => prev + r.totalGames);
          break;
        default:
          sum = 0; // 날짜 등은 합계 없음
      }
      totals[col] = sum;
    }

    return Container(
      height: 50,
      color: BRColors.greenB2,
      child: Row(
        children: PlayerRecordColumn.values.map((col) {
          String display = '';
          if (col == PlayerRecordColumn.date) {
            display = '합계';
          } else if (col == PlayerRecordColumn.winningGames) {
            num value = totals[col]!;
            if (value % 1 == 0) {
              display = '${value.toInt()}경기';
            } else {
              display = '${value.toStringAsFixed(1)}경기';
            }
          } else if (col == PlayerRecordColumn.totalGames) {
            display = '${totals[col]!.toString()}경기';
          } else if (col == PlayerRecordColumn.winScore) {
            display = '${totals[col]!.toString()}점';
          } else if (col == PlayerRecordColumn.attendanceScore) {
            display = '${totals[col]!.toString()}점';
          }
          return Expanded(
            flex: col.flex,
            child: Text(
              display,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.0.responsiveFontSize(context, minFontSize: 15),
                color: Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
    }
}
