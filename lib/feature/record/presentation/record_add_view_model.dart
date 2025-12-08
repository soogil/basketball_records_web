import 'package:flutter/foundation.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/record/data/datasource/record_datasource.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_add_view_model.g.dart';

class PlayerListState {
  PlayerListState({
    required this.players,
  });

  final List<PlayerModel> players;
}

@riverpod
class RecordAddViewModel extends _$RecordAddViewModel {
  RecordDataSource get _recordDataSource => ref.read(recordDataSourceProvider);

  @override
  void build() {}

  Future<bool> hasAnyRealRecordOnDate(String date) async {
    try {
      return await _recordDataSource.hasAnyRealRecordOnDate(date);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}