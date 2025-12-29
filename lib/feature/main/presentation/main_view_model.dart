import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/feature/main/data/datasource/player_datasource.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/record/presentation/record_add_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_view_model.g.dart';


class PlayerListState {
  PlayerListState({
    required this.players,
    required this.seasons,
  });

  final List<PlayerModel> players;
  final List<String> seasons;

  PlayerListState copyWith({
    List<PlayerModel>? players,
    List<String>? seasons,
}) {
    return PlayerListState(
        players: players ?? this.players,
        seasons: seasons ?? this.seasons
    );
  }
}

@riverpod
class MainViewModel extends _$MainViewModel {
  PlayerDataSource get _fireStoreRepository => ref.read(playerDataSourceProvider);

  PlayerColumn? _sortColumn = PlayerColumn.totalScore;
  bool _sortAscending = false;

  PlayerColumn? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;


  @override
  Future<PlayerListState> build() async {
    final selectedSeason = ref.watch(selectedSeasonProvider);

    final seasons = await _getSeason();
    final players = await _fetchPlayers(selectedSeason);

    return PlayerListState(
      seasons: seasons,
      players: players
    );
  }

  Future<List<String>> _getSeason() async {
    final currentSeason = ref.read(currentSeasonProvider);
    final List<String> seasons = await _fireStoreRepository.getSeasons();

    if (!seasons.contains(currentSeason)) {
      seasons.insert(0, currentSeason);
    }

    return seasons;
  }

  Future<List<PlayerModel>> _fetchPlayers(String season) async {
    late final List<PlayerModel> players;
    final currentSeason = ref.read(currentSeasonProvider);

    if (currentSeason == season) {
      players = await _fireStoreRepository.getPlayers();
    } else {
      players = await _fireStoreRepository.getPlayersFromYear(season);
    }

    final sortedPlayers = sortPlayers(players, PlayerColumn.totalScore, ascending: false);

    return sortedPlayers;
  }

  Future addPlayer(String name) async {
    await _fireStoreRepository.addPlayer(name);
  }

  List<PlayerModel> sortPlayers(List<PlayerModel> input, PlayerColumn column, {bool? ascending}) {
    final players = [...input];

    bool defaultAscending = (column == PlayerColumn.name);

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
          compare = 0; // 실제로는 이 케이스에 안옴
          break;
      }
      return _sortAscending ? compare : -compare;
    });

    return players;
  }

  void sortPlayersOnTable(PlayerColumn column) {
    final sorted = sortPlayers(state.value!.players, column);
    state = AsyncData(state.value!.copyWith(
        players: sorted));
  }

  Future savePlayerRecords({
    required String recordDate,
    required List<PlayerGameInput> playerInputs,
  }) async {
    await _fireStoreRepository.updatePlayerRecords(recordDate, playerInputs);
  }

  Future<bool> removeRecordFromDate(String date) async {
    try {
      await _fireStoreRepository.removeRecordFromDate(date);
    } catch(e) {
      debugPrint(e.toString());
      return false;
    }
    return true;
  }

  // 초기화 및 시즌 리셋 기능
  // Future<bool> archiveAndResetSeason() async {
  //   try {
  //     await _fireStoreRepository.archiveAndResetSeason('2025');
  //   } catch(e) {
  //     debugPrint(e.toString());
  //     return false;
  //   }
  //   return true;
  // }
}

final selectedSeasonProvider = StateProvider<String>((ref) {
  final currentSeason = ref.read(currentSeasonProvider);
  return currentSeason;
});
final currentSeasonProvider = StateProvider<String>((ref) {
  DateTime now = DateTime.now();
  // return now.year.toString();
  // todo 새해되면 수정
  return '2026';
});

final isCurrentSeasonProvider = Provider<bool>((ref) {
  final selected = ref.watch(selectedSeasonProvider);
  final current = ref.watch(currentSeasonProvider);
  return selected == current;
});