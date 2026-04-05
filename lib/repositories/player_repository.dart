import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/core/api/firestore_api.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/models/record_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_repository.g.dart';

abstract class PlayerRepository {
  Future<void> addPlayer(String name);
  Future<void> removePlayer(String playerId);
  Future<void> archivePlayer(String playerId);
  Future<void> restorePlayer(String playerId);
  Future<List<PlayerModel>> getInactivePlayers(); // status == 'inactive' 필터
  Future<List<String>> getSeasons();
  Future<List<PlayerModel>> getPlayers();
  Future<List<PlayerModel>> getPlayersFromYear(String year);
  Future<void> updatePlayerRecords(
      String recordDate, List<PlayerGameInput> playerInputs);
  Future<List<RecordModel>> getPlayerRecords(String playerId);
  Future<List<RecordModel>> getPlayerRecordsFromYear(
      String year, String playerId);
  Future<void> removeRecordFromDate(String date);
  Future<bool> hasAnyRealRecordOnDate(String date);
  Future<void> archiveAndResetSeason(String seasonName);
}

class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl(this._api);

  final FireStoreApi _api;

  @override
  Future<void> addPlayer(String name) => _api.addPlayer(name);

  @override
  Future<void> removePlayer(String playerId) => _api.removePlayer(playerId);

  @override
  Future<void> archivePlayer(String playerId) => _api.archivePlayer(playerId);

  @override
  Future<void> restorePlayer(String playerId) => _api.restorePlayer(playerId);

  @override
  Future<List<PlayerModel>> getInactivePlayers() async {
    final snapshot = await _api.getPlayers();
    return snapshot.docs
        .map((doc) => PlayerModel.fromFireStore(doc.id, doc.data()))
        .where((p) => p.status == 'inactive')
        .toList();
  }

  @override
  Future<List<String>> getSeasons() => _api.getSeasons();

  @override
  Future<List<PlayerModel>> getPlayers() async {
    final snapshot = await _api.getPlayers();
    return snapshot.docs
        .map((doc) => PlayerModel.fromFireStore(doc.id, doc.data()))
        .where((p) => p.status == 'active')
        .toList();
  }

  @override
  Future<List<PlayerModel>> getPlayersFromYear(String year) async {
    final snapshot = await _api.getPlayersFromYear(year);
    return snapshot.docs
        .map((doc) => PlayerModel.fromFireStore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> updatePlayerRecords(
          String recordDate, List<PlayerGameInput> playerInputs) =>
      _api.updatePlayerRecords(recordDate, playerInputs);

  @override
  Future<List<RecordModel>> getPlayerRecords(String playerId) async {
    final raw = await _api.getPlayerRecords(playerId);
    final records = raw
        .map((e) => RecordModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  @override
  Future<List<RecordModel>> getPlayerRecordsFromYear(
      String year, String playerId) async {
    final raw = await _api.getPlayerRecordsFromYear(year, playerId);
    final records = raw
        .map((e) => RecordModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  @override
  Future<void> removeRecordFromDate(String date) =>
      _api.removeRecordFromDate(date);

  @override
  Future<bool> hasAnyRealRecordOnDate(String date) =>
      _api.hasAnyRealRecordOnDate(date);

  @override
  Future<void> archiveAndResetSeason(String seasonName) =>
      _api.archiveAndResetSeason(seasonName);
}

@riverpod
PlayerRepository playerRepository(Ref ref) {
  final api = ref.watch(fireStoreApiProvider);
  return PlayerRepositoryImpl(api);
}
