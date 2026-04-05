import 'package:iggys_point/models/record_model.dart';
import 'package:iggys_point/presenters/contracts/player_detail_contract.dart';
import 'package:iggys_point/presenters/main_presenter.dart';
import 'package:iggys_point/repositories/player_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'player_detail_presenter.g.dart';

@riverpod
class PlayerDetailPresenter extends _$PlayerDetailPresenter
    implements IPlayerDetailPresenter {
  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  @override
  Future<PlayerDetailState> build(String playerId) async {
    final records = await _getPlayerRecords(playerId);
    return PlayerDetailState(records: records);
  }

  Future<List<RecordModel>> _getPlayerRecords(String playerId) async {
    final selectedSeason = ref.watch(selectedSeasonProvider);
    final currentSeason = ref.read(currentSeasonProvider);

    if (currentSeason == selectedSeason) {
      return _repository.getPlayerRecords(playerId);
    } else {
      return _repository.getPlayerRecordsFromYear(selectedSeason, playerId);
    }
  }

  @override
  Future<void> removePlayer(String playerId) async {
    await _repository.removePlayer(playerId);
  }

  @override
  Future<void> archivePlayer(String playerId) async {
    await _repository.archivePlayer(playerId);
  }
}
