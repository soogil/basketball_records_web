import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:iggys_point/views/widgets/player_table_cells.dart';

class PlayerTableHeader extends ConsumerWidget {
  const PlayerTableHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.watch(mainPresenterProvider.notifier);
    final int selectedSeason = int.parse(ref.read(selectedSeasonProvider));
    final columns = selectedSeason >= 2026
        ? PlayerColumn.currentYearColumns
        : PlayerColumn.allColumns;

    return Row(
      children: columns.map((col) {
        final isSorted = presenter.sortColumn == col;
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
                        fontSize:
                            16.0.responsiveFontSize(context, minFontSize: 12),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () => presenter.sortPlayersOnTable(col),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          col.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0
                                .responsiveFontSize(context, minFontSize: 12),
                          ),
                        ),
                        if (isSorted)
                          Row(
                            children: [
                              const SizedBox(width: 2),
                              Icon(
                                presenter.sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 20.0.responsiveFontSize(context,
                                    minFontSize: 13),
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
}

class PlayerTableRow extends ConsumerWidget {
  const PlayerTableRow({
    super.key,
    required this.player,
    required this.index,
  });

  final PlayerModel player;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isCurrentSeason = ref.watch(isCurrentSeasonProvider);
    final bool isEven = index.isEven;
    final int selectedSeason = int.parse(ref.read(selectedSeasonProvider));
    final columns = selectedSeason >= 2026
        ? PlayerColumn.currentYearColumns
        : PlayerColumn.allColumns;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 50,
      onTap: () => context.pushNamed(AppPage.playerDetail.name, extra: {
        'playerId': player.id,
        'playerName': player.name,
      }).then((refresh) {
        if ((refresh as bool?) ?? false) {
          ref.invalidate(mainPresenterProvider);
        }
      }),
      tileColor: isEven ? BRColors.greyDa : BRColors.whiteE8,
      title: Row(
        mainAxisSize: MainAxisSize.max,
        children: columns
            .map(
              (col) => Expanded(
                flex: col.flex,
                child: col == PlayerColumn.accumulatedScore
                    ? PlayerAccumulatedCell(
                        player: player,
                        isCurrentSeason: isCurrentSeason,
                        mode: ScoreDisplayMode.progressBar,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            player.valueByColumn(col, index: index + 1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: BRColors.black,
                              fontSize: 18.0.responsiveFontSize(context,
                                  minFontSize: 13),
                            ),
                          ),
                        ],
                      ),
              ),
            )
            .toList(),
      ),
    );
  }
}
