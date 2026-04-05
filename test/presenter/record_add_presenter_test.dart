import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/models/record_model.dart';
import 'package:iggys_point/presenters/record_add_presenter.dart';
import 'package:iggys_point/repositories/player_repository.dart';

/// 테스트용 가짜 Repository — 실제 Firestore 호출 없이 동작 검증
class FakePlayerRepository implements PlayerRepository {
  // 마지막으로 호출된 인수를 저장
  String? lastSavedDate;
  List<PlayerGameInput>? lastSavedInputs;
  String? lastRemovedDate;
  String? lastCheckedDate;

  // 제어 플래그
  bool hasRecord = false;

  @override
  Future<void> updatePlayerRecords(
      String recordDate, List<PlayerGameInput> playerInputs) async {
    lastSavedDate = recordDate;
    lastSavedInputs = playerInputs;
  }

  @override
  Future<void> removeRecordFromDate(String date) async {
    lastRemovedDate = date;
  }

  @override
  Future<bool> hasAnyRealRecordOnDate(String date) async {
    lastCheckedDate = date;
    return hasRecord;
  }

  // 아래는 이번 테스트에서 사용 안 함
  @override Future<void> addPlayer(String name) async {}
  @override Future<void> removePlayer(String playerId) async {}
  @override Future<void> archivePlayer(String playerId) async {}
  @override Future<void> restorePlayer(String playerId) async {}
  @override Future<List<PlayerModel>> getInactivePlayers() async => [];
  @override Future<List<String>> getSeasons() async => [];
  @override Future<List<PlayerModel>> getPlayers() async => [];
  @override Future<List<PlayerModel>> getPlayersFromYear(String year) async => [];
  @override Future<List<RecordModel>> getPlayerRecords(String playerId) async => [];
  @override Future<List<RecordModel>> getPlayerRecordsFromYear(String year, String playerId) async => [];
  @override Future<void> archiveAndResetSeason(String seasonName) async {}
}

PlayerModel _makeModel(String id, String name) => PlayerModel(
      id: id,
      name: name,
      totalScore: 0,
      attendanceScore: 0,
      accumulatedScore: 0,
      winScore: 0,
      seasonTotalGames: 0,
      seasonTotalWins: 0.0,
      scoreAchieved: false,
    );

void main() {
  late FakePlayerRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    fakeRepo = FakePlayerRepository();
    container = ProviderContainer(
      overrides: [
        playerRepositoryProvider.overrideWith((_) => fakeRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('RecordAddPresenter.saveRecords', () {
    test('날짜 포맷이 yyyy-MM-dd로 올바르게 변환된다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      await presenter.saveRecords(
        DateTime(2025, 6, 5),
        [],
        [],
      );

      expect(fakeRepo.lastSavedDate, '2025-06-05');
    });

    test('한 자리 월/일도 zero-padding 처리된다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      await presenter.saveRecords(DateTime(2025, 1, 9), [], []);

      expect(fakeRepo.lastSavedDate, '2025-01-09');
    });

    test('팀 선수들이 flat하게 합쳐져서 전달된다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      final p1 = _makeModel('p1', 'Curry');
      final p2 = _makeModel('p2', 'Durant');
      final p3 = _makeModel('p3', 'Klay');

      final input1 = PlayerGameInput(player: p1, attendanceScore: 15);
      final input2 = PlayerGameInput(player: p2, attendanceScore: 15);
      final input3 = PlayerGameInput(player: p3, attendanceScore: 10);

      final teams = [
        TeamInput(teamName: '팀 1', players: [input1, input2]),
        TeamInput(teamName: '팀 2', players: [input3]),
      ];

      await presenter.saveRecords(DateTime(2025, 6, 1), teams, []);

      expect(fakeRepo.lastSavedInputs!.length, 3);
      expect(
          fakeRepo.lastSavedInputs!.map((e) => e.playerId).toList(),
          containsAll(['p1', 'p2', 'p3']));
    });

    test('결석 선수(nonAttendants)는 attendanceScore=0으로 자동 추가된다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      final absent1 = _makeModel('a1', 'Bench1');
      final absent2 = _makeModel('a2', 'Bench2');

      await presenter.saveRecords(
        DateTime(2025, 6, 1),
        [],                        // 팀 없음
        [absent1, absent2],        // 결석 선수 2명
      );

      expect(fakeRepo.lastSavedInputs!.length, 2);
      for (final input in fakeRepo.lastSavedInputs!) {
        expect(input.attendanceScore, 0);
      }
    });

    test('팀 선수 + 결석 선수가 합쳐져서 전체 선수가 모두 전달된다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      final active = _makeModel('p1', 'Active');
      final absent = _makeModel('p2', 'Absent');

      final teamInput = PlayerGameInput(player: active, attendanceScore: 15);
      final teams = [TeamInput(teamName: '팀 1', players: [teamInput])];

      await presenter.saveRecords(
        DateTime(2025, 6, 1),
        teams,
        [absent],
      );

      expect(fakeRepo.lastSavedInputs!.length, 2);

      final activeResult = fakeRepo.lastSavedInputs!
          .firstWhere((e) => e.playerId == 'p1');
      final absentResult = fakeRepo.lastSavedInputs!
          .firstWhere((e) => e.playerId == 'p2');

      expect(activeResult.attendanceScore, 15);
      expect(absentResult.attendanceScore, 0);
    });
  });

  group('RecordAddPresenter.removeRecordFromDate', () {
    test('날짜 포맷이 yyyy-MM-dd로 올바르게 변환되어 repository에 전달된다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      await presenter.removeRecordFromDate(DateTime(2025, 3, 7));

      expect(fakeRepo.lastRemovedDate, '2025-03-07');
    });

    test('정상 삭제 시 true를 반환한다', () async {
      final presenter = container.read(recordAddPresenterProvider.notifier);

      final result =
          await presenter.removeRecordFromDate(DateTime(2025, 6, 1));

      expect(result, true);
    });

    test('repository 예외 발생 시 false를 반환한다', () async {
      // 예외 던지는 가짜 repo
      final failRepo = _FailingRemoveRepository();
      final failContainer = ProviderContainer(overrides: [
        playerRepositoryProvider.overrideWith((_) => failRepo),
      ]);
      addTearDown(failContainer.dispose);

      final presenter =
          failContainer.read(recordAddPresenterProvider.notifier);
      final result =
          await presenter.removeRecordFromDate(DateTime(2025, 6, 1));

      expect(result, false);
    });
  });

  group('RecordAddPresenter.hasAnyRealRecordOnDate', () {
    test('기록이 있으면 true를 반환한다', () async {
      fakeRepo.hasRecord = true;
      final presenter = container.read(recordAddPresenterProvider.notifier);

      final result =
          await presenter.hasAnyRealRecordOnDate('2025-06-01');

      expect(result, true);
      expect(fakeRepo.lastCheckedDate, '2025-06-01');
    });

    test('기록이 없으면 false를 반환한다', () async {
      fakeRepo.hasRecord = false;
      final presenter = container.read(recordAddPresenterProvider.notifier);

      final result =
          await presenter.hasAnyRealRecordOnDate('2025-06-01');

      expect(result, false);
    });
  });
}

class _FailingRemoveRepository extends FakePlayerRepository {
  @override
  Future<void> removeRecordFromDate(String date) async {
    throw Exception('Firestore error');
  }
}
