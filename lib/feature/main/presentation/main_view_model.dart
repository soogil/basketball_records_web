import 'package:flutter/material.dart';
import 'package:iggys_point/feature/main/data/datasource/player_datasource.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/record/presentation/record_add_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_view_model.g.dart';


class PlayerListState {
  PlayerListState({
    required this.players,
  });

  final List<PlayerModel> players;
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
    final List<PlayerModel> players = await _fireStoreRepository.getPlayers();

    debugPrint(players.length.toString());

    final sorted = sortPlayers(players, PlayerColumn.totalScore, ascending: false);

    return PlayerListState(players: sorted);
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
    state = AsyncData(PlayerListState(players: sorted));
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
}