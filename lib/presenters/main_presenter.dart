import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/contracts/main_contract.dart';
import 'package:iggys_point/repositories/player_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_presenter.g.dart';

@riverpod
class MainPresenter extends _$MainPresenter implements IMainPresenter {
  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  PlayerColumn? _sortColumn = PlayerColumn.totalScore;
  bool _sortAscending = false;

  PlayerColumn? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  @override
  Future<MainState> build() async {
    final selectedSeason = ref.watch(selectedSeasonProvider);
    final seasons = await _getSeasons();
    final players = await _fetchPlayers(selectedSeason);
    return MainState(seasons: seasons, players: players);
  }

  Future<List<String>> _getSeasons() async {
    final currentSeason = ref.read(currentSeasonProvider);
    final seasons = await _repository.getSeasons();
    if (!seasons.contains(currentSeason)) {
      seasons.insert(0, currentSeason);
    }
    return seasons;
  }

  Future<List<PlayerModel>> _fetchPlayers(String season) async {
    final currentSeason = ref.read(currentSeasonProvider);
    final bool isNewSeason = int.parse(currentSeason) >= 2026;

    final List<PlayerModel> players = currentSeason == season
        ? await _repository.getPlayers()
        : await _repository.getPlayersFromYear(season);

    return sortPlayers(
      players,
      isNewSeason ? PlayerColumn.attendanceScore : PlayerColumn.totalScore,
      ascending: false,
    );
  }

  @override
  Future<void> addPlayer(String name) async {
    await _repository.addPlayer(name);
  }

  @override
  Future<List<PlayerModel>> getInactivePlayers() async {
    return _repository.getInactivePlayers();
  }

  @override
  Future<void> restorePlayer(String playerId) async {
    await _repository.restorePlayer(playerId);
  }

  List<PlayerModel> sortPlayers(
    List<PlayerModel> input,
    PlayerColumn column, {
    bool? ascending,
  }) {
    final players = [...input];
    final bool defaultAscending = column == PlayerColumn.name;

    if (_sortColumn == column) {
      _sortAscending = ascending ?? !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = ascending ?? defaultAscending;
    }

    players.sort((a, b) {
      int compare;
      switch (column) {
        case PlayerColumn.name:
          compare = a.name.compareTo(b.name);
          break;
        case PlayerColumn.winScore:
          compare = a.winScore.compareTo(b.winScore);
          break;
        case PlayerColumn.accumulatedScore:
          compare = a.accumulatedScore.compareTo(b.accumulatedScore);
          break;
        case PlayerColumn.totalScore:
          compare = a.totalScore.compareTo(b.totalScore);
          break;
        case PlayerColumn.attendanceScore:
          compare = a.attendanceScore.compareTo(b.attendanceScore);
          break;
        case PlayerColumn.winRate:
          compare = a.winRate.compareTo(b.winRate);
          break;
        case PlayerColumn.rank:
          compare = 0;
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    return players;
  }

  @override
  void sortPlayersOnTable(PlayerColumn column) {
    final sorted = sortPlayers(state.value!.players, column);
    state = AsyncData(state.value!.copyWith(players: sorted));
  }

}

final selectedSeasonProvider = StateProvider<String>((ref) {
  return ref.read(currentSeasonProvider);
});

final currentSeasonProvider = StateProvider<String>((ref) {
  return DateTime.now().year.toString();
});

final isCurrentSeasonProvider = Provider<bool>((ref) {
  final selected = ref.watch(selectedSeasonProvider);
  final current = ref.watch(currentSeasonProvider);
  return selected == current;
});
