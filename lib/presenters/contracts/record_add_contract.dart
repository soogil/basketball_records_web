import 'package:iggys_point/models/player_model.dart';

/// RecordAddScreen이 Presenter에게 요청할 수 있는 메서드 목록
abstract class IRecordAddPresenter {
  Future<bool> hasAnyRealRecordOnDate(String date);
  Future<void> saveRecords(
    DateTime date,
    List<TeamInput> teams,
    List<PlayerModel> nonAttendants,
  );
  Future<bool> removeRecordFromDate(DateTime date);
}
