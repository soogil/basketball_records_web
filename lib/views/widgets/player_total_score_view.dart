import 'package:flutter/material.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/record_model.dart';

class PlayerTotalScoreView extends StatelessWidget {
  const PlayerTotalScoreView({
    super.key,
    required this.records,
    required this.columns,
  });

  final List<RecordModel> records;
  final List<PlayerRecordColumn> columns;

  @override
  Widget build(BuildContext context) {
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
          totals[col] =
              records.fold<double>(0.0, (prev, r) => prev + r.winningGames);
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
