import 'package:iggys_point/models/record_model.dart';

/// PlayerDetailScreen이 Presenter에게 요청할 수 있는 메서드 목록
abstract class IPlayerDetailPresenter {
  Future<void> removePlayer(String playerId);
  Future<void> archivePlayer(String playerId);
}

/// Presenter가 PlayerDetailScreen에 전달할 상태
class PlayerDetailState {
  PlayerDetailState({required this.records});

  final List<RecordModel> records;
}
