import 'package:iggys_point/feature/main/data/datasource/player_datasource.dart';
import 'package:iggys_point/feature/main/presentation/main_view_model.dart';
import 'package:iggys_point/feature/record/data/models/record_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_detail_record_view_model.g.dart';

class DateRecords {
  DateRecords({required this.records});

  final List<RecordModel> records;
}

@riverpod
class PlayerDetailRecordViewModel extends _$PlayerDetailRecordViewModel {
  PlayerDataSource get _playerDataSource => ref.read(playerDataSourceProvider);

  @override
  Future<DateRecords> build(String playerId) async {
    final List<RecordModel> records = await _getPlayerRecord(playerId);

    return DateRecords(records: records);
  }

  Future<List<RecordModel>> _getPlayerRecord(String playerId) async {
    final String selectedSeason = ref.watch(selectedSeasonProvider);
    final String currentSeason = ref.read(currentSeasonProvider);
    late final List<RecordModel> records;

    if (currentSeason == selectedSeason) {
      records = await _playerDataSource.getPlayerRecords(playerId);
    } else {
      records = await _playerDataSource.getPlayerRecordsFromYear(selectedSeason, playerId);
    }

    return records;
  }

  Future removePlayer(String playerId) async {
    await _playerDataSource.removePlayer(playerId);
  }
}