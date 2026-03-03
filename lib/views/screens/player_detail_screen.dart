import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/record_model.dart';
import 'package:iggys_point/presenters/contracts/player_detail_contract.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:iggys_point/presenters/player_detail_presenter.dart';
import 'package:iggys_point/views/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

final _tapCountProvider = StateProvider<int>((ref) => 0);

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  final String playerId;
  final String playerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenterState =
        ref.watch(playerDetailPresenterProvider(playerId));

    return Scaffold(
      appBar: _appBar(context, ref),
      body: presenterState.when(
        data: (data) => _body(context, data, ref),
        error: (_, e) => Text(e.toString()),
        loading: () => Center(
            child: CircularProgressIndicator(color: BRColors.greyDa)),
      ),
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
            color: BRColors.white,
          ),
        ),
      ),
      actions: tapCount < 7
          ? []
          : [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white)),
                onPressed: () async {
                  final bool? confirm =
                      await _showRemovePlayerDialog(context);

                  if (confirm ?? false) {
                    final presenter = ref.read(
                        playerDetailPresenterProvider(playerId).notifier);
                    await presenter.removePlayer(playerId);

                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                },
                child: Text(
                  '선수 삭제',
                  style: TextStyle(
                    fontSize:
                        15.0.responsiveFontSize(context, minFontSize: 12),
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 50),
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
                  fontSize:
                      15.0.responsiveFontSize(context, minFontSize: 12),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize:
                      15.0.responsiveFontSize(context, minFontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, PlayerDetailState state, WidgetRef ref) {
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
                      return _buildTableRow(context, ref, record, index);
                    },
                    childCount: state.records.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        _totalState(context, ref, state.records),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final int selectedSeason = int.parse(ref.read(selectedSeasonProvider));
    final List<PlayerRecordColumn> columns = selectedSeason >= 2026
        ? PlayerRecordColumn.currentYearColumns
        : PlayerRecordColumn.allColumns;

    return Row(
      children: columns.map((col) {
        return Expanded(
          flex: col.flex,
          child: Container(
            color: BRColors.greenCf,
            height: 50,
            child: InkWell(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    col.label,
                    style: TextStyle(
                      fontSize: 16.0
                          .responsiveFontSize(context, minFontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    WidgetRef ref,
    RecordModel record,
    int index,
  ) {
    final isEven = index.isEven;
    final int selectedSeason = int.parse(ref.read(selectedSeasonProvider));
    final List<PlayerRecordColumn> columns = selectedSeason >= 2026
        ? PlayerRecordColumn.currentYearColumns
        : PlayerRecordColumn.allColumns;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 50,
      tileColor: isEven ? BRColors.greyDa : BRColors.whiteE8,
      title: Row(
        mainAxisSize: MainAxisSize.max,
        children: columns
            .map(
              (col) => Expanded(
                flex: col.flex,
                child: Text(
                  record.valueByColumn(col),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:
                        18.0.responsiveFontSize(context, minFontSize: 15),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _totalState(
    BuildContext context,
    WidgetRef ref,
    List<RecordModel> records,
  ) {
    final int selectedSeason = int.parse(ref.read(selectedSeasonProvider));
    final List<PlayerRecordColumn> columns = selectedSeason >= 2026
        ? PlayerRecordColumn.currentYearColumns
        : PlayerRecordColumn.allColumns;

    final Map<PlayerRecordColumn, num> totals = {};
    for (final col in PlayerRecordColumn.values) {
      switch (col) {
        case PlayerRecordColumn.attendanceScore:
          totals[col] =
              records.fold<int>(0, (prev, r) => prev + r.attendanceScore);
          break;
        case PlayerRecordColumn.winScore:
          totals[col] =
              records.fold<int>(0, (prev, r) => prev + r.winScore);
          break;
        case PlayerRecordColumn.winningGames:
          totals[col] = records.fold<double>(
              0.0, (prev, r) => prev + r.winningGames);
          break;
        case PlayerRecordColumn.totalGames:
          totals[col] =
              records.fold<int>(0, (prev, r) => prev + r.totalGames);
          break;
        default:
          totals[col] = 0;
      }
    }

    return Container(
      height: 50,
      color: BRColors.greenB2,
      child: Row(
        children: columns.map((col) {
          String display = '';
          if (col == PlayerRecordColumn.date) {
            display = '합계';
          } else if (col == PlayerRecordColumn.winningGames) {
            final num value = totals[col]!;
            display = value % 1 == 0
                ? '${value.toInt()}경기'
                : '${value.toStringAsFixed(1)}경기';
          } else if (col == PlayerRecordColumn.totalGames) {
            display = '${totals[col]!}경기';
          } else if (col == PlayerRecordColumn.winScore) {
            display = '${totals[col]!}점';
          } else if (col == PlayerRecordColumn.attendanceScore) {
            display = '${totals[col]!}점';
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
