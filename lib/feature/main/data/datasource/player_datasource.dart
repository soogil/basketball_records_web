import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/core/api/firestore_api.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/record/data/models/record_model.dart';
import 'package:iggys_point/feature/record/presentation/record_add_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_datasource.g.dart';

abstract class PlayerDataSource {
  Future<void> addPlayer(String name);
  Future<void> removePlayer(String playerId);
  Future<void> uploadPlayers();
  Future<void> removeRecordFromDate(String date);
  Future<List<PlayerModel>> getPlayers();
  Future<void> updatePlayerRecords(String recordDate, List<PlayerGameInput> player);
  Future<List<RecordModel>> getPlayerRecords(String playerId);
}

class PlayerDatasourceImpl implements PlayerDataSource {
  PlayerDatasourceImpl(this._fireStoreApi);

  final FireStoreApi _fireStoreApi;

  @override
  Future<void> addPlayer(String name) async {
    await _fireStoreApi.addPlayer(name);
  }

  @override
  Future<void> removePlayer(String playerId) async {
    await _fireStoreApi.removePlayer(playerId);
  }

  @override
  Future<void> uploadPlayers() async {
    return _fireStoreApi.uploadPlayersToFireStore();
  }

  @override
  Future<void> removeRecordFromDate(String date) async {
    await _fireStoreApi.removeRecordFromDate(date);
  }

  @override
  Future<List<PlayerModel>> getPlayers() async {
    final result = await _fireStoreApi.getPlayers();
    return result.docs.map((doc) {
      return PlayerModel.fromFireStore(doc.id, doc.data());
    }).toList();
  }

  @override
  Future<void> updatePlayerRecords(String recordDate, List<PlayerGameInput> player) async {
    await _fireStoreApi.updatePlayerRecords(recordDate, player);
  }

  @override
  Future<List<RecordModel>> getPlayerRecords(String playerId) async {
    final result = await _fireStoreApi.getPlayerRecords(playerId);

    final records = result.map((e) => RecordModel.fromJson(Map<String, dynamic>.from(e))).toList();

    records.sort((a, b) => b.date.compareTo(a.date));

    return records;
  }
}

@riverpod
PlayerDataSource playerDataSource(Ref ref) {
  final api = ref.watch(fireStoreApiProvider);
  return PlayerDatasourceImpl(api);
}