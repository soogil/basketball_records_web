import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/core/theme/br_color.dart';
import 'package:iggys_point/core/utils.dart';
import 'package:iggys_point/presenters/contracts/main_contract.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:iggys_point/views/widgets/inactive_players_dialog.dart';

final mainAdminModeProvider = StateProvider<bool>((ref) => false);

class MainAppBar extends ConsumerWidget {
  const MainAppBar({
    super.key,
    required this.state,
    required this.isCapturing,
    required this.onCapture,
  });

  final MainState state;
  final bool isCapturing;
  final Future<void> Function(MainState) onCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool adminMode = ref.watch(mainAdminModeProvider);
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
            final currentYear =
                isCurrentYear ? DateTime.now().year.toString() : season;
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
                    final String? name = await _showPlayerNameDialog(context);
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
                            content: Text(e
                                .toString()
                                .replaceFirst('Exception: ', '')),
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
                        onRestored: () =>
                            ref.invalidate(mainPresenterProvider),
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

  Future<String?> _showPlayerNameDialog(BuildContext context) {
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
}
