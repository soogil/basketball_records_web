import 'package:flutter/foundation.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/presenters/contracts/record_add_contract.dart';
import 'package:iggys_point/repositories/player_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_add_presenter.g.dart';

@riverpod
class RecordAddPresenter extends _$RecordAddPresenter
    implements IRecordAddPresenter {
  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  @override
  void build() {}

  @override
  Future<bool> hasAnyRealRecordOnDate(String date) async {
    try {
      return await _repository.hasAnyRealRecordOnDate(date);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  @override
  Future<void> saveRecords(
    DateTime date,
    List<TeamInput> teams,
    List<PlayerModel> nonAttendants,
  ) async {
    final recordDate = _formatDate(date);

    final playerInputs = teams.expand((team) => team.players).toList();

    final absentInputs = nonAttendants
        .map((player) => PlayerGameInput(player: player, attendanceScore: 0))
        .toList();

    await _repository.updatePlayerRecords(
      recordDate,
      [...playerInputs, ...absentInputs],
    );
  }

  @override
  Future<bool> removeRecordFromDate(DateTime date) async {
    try {
      await _repository.removeRecordFromDate(_formatDate(date));
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}
