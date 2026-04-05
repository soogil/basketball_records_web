import 'package:iggys_point/models/player_model.dart';

/// MainScreen이 Presenter에게 요청할 수 있는 메서드 목록
abstract class IMainPresenter {
  Future<void> addPlayer(String name);
  void sortPlayersOnTable(PlayerColumn column);
  Future<List<PlayerModel>> getInactivePlayers();
  Future<void> restorePlayer(String playerId);
}

/// Presenter가 MainScreen에게 전달할 상태
class MainState {
  MainState({
    required this.players,
    required this.seasons,
  });

  final List<PlayerModel> players;
  final List<String> seasons;

  MainState copyWith({
    List<PlayerModel>? players,
    List<String>? seasons,
  }) {
    return MainState(
      players: players ?? this.players,
      seasons: seasons ?? this.seasons,
    );
  }
}
