import 'package:flutter/material.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/record_model.dart';

class RecordTableHeader extends StatelessWidget {
  const RecordTableHeader({super.key, required this.columns});

  final List<PlayerRecordColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: columns.map((col) {
        return Expanded(
          flex: col.flex,
          child: Container(
            color: BRColors.greenCf,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  col.label,
                  style: TextStyle(
                    fontSize:
                        16.0.responsiveFontSize(context, minFontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class RecordTableRow extends StatelessWidget {
  const RecordTableRow({
    super.key,
    required this.record,
    required this.index,
    required this.columns,
  });

  final RecordModel record;
  final int index;
  final List<PlayerRecordColumn> columns;

  @override
  Widget build(BuildContext context) {
    final isEven = index.isEven;

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
}
