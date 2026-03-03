import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/contracts/main_contract.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

final _tapCountProvider = StateProvider<int>((ref) => 0);
final isMobileProvider = Provider.family<bool, BuildContext>((ref, context) {
  return MediaQuery.of(context).size.width < 600;
});

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

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
    final presenterState = ref.watch(mainPresenterProvider);

    return RefreshIndicator(
      onRefresh: deleteAllCookies,
      child: presenterState.when(
        data: (data) => Scaffold(body: _recordView(context, ref, data)),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('에러 발생: $error')),
      ),
    );
  }

  SliverAppBar _appBar(
    BuildContext context,
    WidgetRef ref,
    MainState state,
  ) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이기스 포인트 $selectedSeason',
              style: TextStyle(
                fontSize: 24.0.responsiveFontSize(context, minFontSize: 18),
                color: BRColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
        itemBuilder: (BuildContext context) {
          return state.seasons.map((season) {
            final isCurrentYear = season.isEmpty;
            final currentYear = isCurrentYear
                ? DateTime.now().year.toString()
                : season;
            return PopupMenuItem<String>(
              value: season,
              child: Text('이기스 포인트 $currentYear'),
            );
          }).toList();
        },
      ),
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
      actions: tapCount < 7
          ? []
          : [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white)),
                onPressed: () async {
                  final String? name = await showPlayerNameDialog(context);
                  if (name?.isNotEmpty ?? false) {
                    final presenter =
                        ref.read(mainPresenterProvider.notifier);
                    await presenter.addPlayer(name!);
                    ref.invalidate(mainPresenterProvider);
                  }
                },
                child: Text(
                  '선수 추가',
                  style: TextStyle(
                    fontSize:
                        15.0.responsiveFontSize(context, minFontSize: 12),
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                  width:
                      10.0.responsiveFontSize(context, minFontSize: 8)),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white)),
                onPressed: () {
                  final players =
                      ref.read(mainPresenterProvider).value?.players ?? [];

                  context.pushNamed(
                    AppPage.recordAdd.name,
                    extra: players,
                  ).then((_) {
                    ref.invalidate(mainPresenterProvider);
                  });
                },
                child: Text(
                  '기록 추가',
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

  Future<String?> showPlayerNameDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('선수 이름 입력'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '이름을 입력하세요'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Widget _recordView(BuildContext context, WidgetRef ref, MainState state) {
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
                        fontSize: 16.0
                            .responsiveFontSize(context, minFontSize: 12),
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
                            fontSize: 16.0.responsiveFontSize(context,
                                minFontSize: 12),
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

  Widget _buildTableRow(
    BuildContext context,
    WidgetRef ref,
    PlayerModel player,
    int index,
  ) {
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
                            : FontWeight.normal,
                        fontSize: 18.0
                            .responsiveFontSize(context, minFontSize: 13),
                      ),
                    ),
                    if (col == PlayerColumn.accumulatedScore &&
                        player.scoreAchieved &&
                        isCurrentSeason)
                      const Row(
                        children: [
                          SizedBox(width: 5),
                          Icon(Icons.emoji_events, color: Colors.amber),
                        ],
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
