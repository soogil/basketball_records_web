import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/main/presentation/main_page.dart';
import 'package:iggys_point/feature/player_detail/presentation/player_detail_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iggys_point/feature/record/presentation/record_add_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';


@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppPage.main.path,
    routes: [
      GoRoute(
        path: AppPage.main.path,
        name: AppPage.main.name,
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: AppPage.playerDetail.path,
        name: AppPage.playerDetail.name,
        builder: (context, state) {
          final Map data = state.extra as Map;

          final String playerId = data['playerId'];
          final String playerName = data['playerName'];

          return PlayerDetailPage(playerId: playerId, playerName: playerName);
        },
      ),
      GoRoute(
        path: AppPage.recordAdd.path,
        name: AppPage.recordAdd.name,
        builder: (context, state) {
          final Map data = state.extra as Map;

          final List<PlayerModel> players = data['allPlayers'];
          final Function(DateTime selectedDate, List<TeamInput>, List<PlayerModel>) onSave = data['onSave'];
          final Function(DateTime date)? onRemove = data['onRemove'];

          return RecordAddPage(
            allPlayers: players,
            onSave: onSave,
            onRemove: onRemove,
          );
        },
      ),
    ],
  );
}