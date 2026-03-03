import 'package:iggys_point/core/router/app_pages.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/views/screens/main_screen.dart';
import 'package:iggys_point/views/screens/player_detail_screen.dart';
import 'package:iggys_point/views/screens/record_add_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: AppPage.playerDetail.path,
        name: AppPage.playerDetail.name,
        builder: (context, state) {
          final Map data = state.extra as Map;
          final String playerId = data['playerId'];
          final String playerName = data['playerName'];
          return PlayerDetailScreen(
              playerId: playerId, playerName: playerName);
        },
      ),
      GoRoute(
        path: AppPage.recordAdd.path,
        name: AppPage.recordAdd.name,
        builder: (context, state) {
          final players = state.extra as List<PlayerModel>;
          return RecordAddScreen(allPlayers: players);
        },
      ),
    ],
  );
}
