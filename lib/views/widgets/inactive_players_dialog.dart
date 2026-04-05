import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/main_presenter.dart';

class InactivePlayersDialog extends ConsumerStatefulWidget {
  const InactivePlayersDialog({super.key, required this.onRestored});
  final VoidCallback onRestored;

  @override
  ConsumerState<InactivePlayersDialog> createState() =>
      _InactivePlayersDialogState();
}

class _InactivePlayersDialogState
    extends ConsumerState<InactivePlayersDialog> {
  List<PlayerModel>? _players;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players =
        await ref.read(mainPresenterProvider.notifier).getInactivePlayers();
    if (mounted) {
      setState(() {
        _players = players;
        _loading = false;
      });
    }
  }

  Future<void> _restore(String playerId) async {
    await ref.read(mainPresenterProvider.notifier).restorePlayer(playerId);
    widget.onRestored();
    await _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('휴면 선수 목록'),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _players!.isEmpty
              ? const Text('휴면 선수가 없습니다.')
              : SizedBox(
                  width: 320,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _players!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final player = _players![index];
                      return ListTile(
                        title: Text(player.name),
                        trailing: TextButton(
                          onPressed: () => _restore(player.id),
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
