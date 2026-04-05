import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/contracts/main_contract.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import 'package:iggys_point/views/widgets/inactive_players_dialog.dart';
import 'package:iggys_point/views/widgets/player_table_cells.dart';

final _adminModeProvider = StateProvider<bool>((ref) => false);
final isMobileProvider = Provider.family<bool, BuildContext>((ref, context) {
  return MediaQuery.of(context).size.width < 600;
});

class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final captureKey = useMemoized(() => GlobalKey());
    final isCapturingState = useState<bool>(false);
    final captureState = useState<MainState?>(null);

    Future<void> captureFullList(MainState state) async {
      isCapturingState.value = true;
      captureState.value = state;

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 80));

      try {
        final boundary = captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) return;

        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) return;

        final bytes = Uint8List.view(byteData.buffer);
        final blob = web.Blob(
          [bytes.toJS].toJS,
          web.BlobPropertyBag(type: 'image/png'),
        );
        final url = web.URL.createObjectURL(blob);
        final anchor =
            web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = url;
        anchor.download =
            '이기스포인트_${ref.read(selectedSeasonProvider)}.png';
        web.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        web.URL.revokeObjectURL(url);
      } finally {
        isCapturingState.value = false;
        captureState.value = null;
      }
    }

    bool handleKeyEvent(KeyEvent event) {
      if (event is KeyDownEvent &&
          HardwareKeyboard.instance.isControlPressed &&
          HardwareKeyboard.instance.isShiftPressed &&
          event.logicalKey == LogicalKeyboardKey.keyA) {
        ref.read(_adminModeProvider.notifier).state = true;
        return true;
      }
      return false;
    }

    useEffect(() {
      HardwareKeyboard.instance.addHandler(handleKeyEvent);
      return () => HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    }, []);

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

    final presenterState = ref.watch(mainPresenterProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: deleteAllCookies,
            child: presenterState.when(
              skipLoadingOnReload: true,
              data: (state) => CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  _appBar(
                    context,
                    ref,
                    state,
                    isCapturingState.value,
                    captureFullList,
                  ),
                  SliverStickyHeader(
                    header: _buildHeader(context, ref),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        state.players.asMap().entries
                            .map((e) => _buildTableRow(context, ref, e.value, e.key))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('에러 발생: $error')),
            ),
          ),
          if (isCapturingState.value && captureState.value != null)
            Positioned(
              left: -(screenWidth + 100),
              top: 0,
              width: screenWidth,
              child: RepaintBoundary(
                key: captureKey,
                child: Material(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(context, ref),
                      ...captureState.value!.players.asMap().entries.map(
                            (e) => _buildTableRow(
                                context, ref, e.value, e.key),
                          ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _appBar(
    BuildContext context,
    WidgetRef ref,
    MainState state,
    bool isCapturing,
    Future<void> Function(MainState) onCapture,
  ) {
    final bool adminMode = ref.watch(_adminModeProvider);
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
      actions: !adminMode
          ? []
          : [
            IconButton(
              tooltip: '전체 목록 이미지 저장',
              icon: isCapturing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white),
              onPressed: isCapturing ? null : () => onCapture(state),
            ),
            ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white)),
                onPressed: () async {
                  final String? name = await showPlayerNameDialog(context);
                  if (!(name?.isNotEmpty ?? false)) return;
                  try {
                    final presenter =
                        ref.read(mainPresenterProvider.notifier);
                    await presenter.addPlayer(name!);
                    ref.invalidate(mainPresenterProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
                  width: 10.0.responsiveFontSize(context, minFontSize: 8)),
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
              SizedBox(
                  width: 10.0.responsiveFontSize(context, minFontSize: 8)),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => InactivePlayersDialog(
                      onRestored: () => ref.invalidate(mainPresenterProvider),
                    ),
                  );
                },
                child: Text(
                  '휴면 선수',
                  style: TextStyle(
                    fontSize:
                        15.0.responsiveFontSize(context, minFontSize: 12),
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 50),
            ],
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
                              fontSize: 18.0.responsiveFontSize(
                                  context, minFontSize: 13),
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
