import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/main_presenter.dart';

class InactivePlayersDialog extends HookConsumerWidget {
  const InactivePlayersDialog({super.key, required this.onRestored});
  final VoidCallback onRestored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = useState<List<PlayerModel>?>(null);
    final loadingState = useState<bool>(true);

    Future<void> loadPlayers() async {
      loadingState.value = true;
      final players =
          await ref.read(mainPresenterProvider.notifier).getInactivePlayers();
      playersState.value = players;
      loadingState.value = false;
    }

    useEffect(() {
      loadPlayers();
      return null;
    }, const []);

    Future<void> restore(String playerId) async {
      await ref.read(mainPresenterProvider.notifier).restorePlayer(playerId);
      onRestored();
      await loadPlayers();
    }

    return AlertDialog(
      title: const Text('휴면 선수 목록'),
      content: loadingState.value
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : playersState.value!.isEmpty
              ? const Text('휴면 선수가 없습니다.')
              : SizedBox(
                  width: 320,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: playersState.value!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final player = playersState.value![index];
                      return ListTile(
                        title: Text(player.name),
                        trailing: TextButton(
                          onPressed: () => restore(player.id),
                          child: const Text('복귀'),
                        ),
                      );
                    },
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
