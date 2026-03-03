import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iggys_point/core/api/firestore_api.dart';
import 'package:iggys_point/models/player_model.dart';

/// PlayerGameInput을 테스트용으로 간단히 만드는 헬퍼
PlayerGameInput _makeInput(
  PlayerModel player, {
  int attendanceScore = 15,
  String totalGames = '0',
  String winGames = '0',
  String winScore = '0',
}) {
  final input = PlayerGameInput(player: player, attendanceScore: attendanceScore);
  input.totalGamesController.text = totalGames;
  input.winGamesController.text = winGames;
  input.winScoreController.text = winScore;
  return input;
}

/// Firestore에 기본 플레이어 문서를 생성하는 헬퍼
Future<void> _seedPlayer(
  FakeFirebaseFirestore fake,
  String playerId, {
  String name = 'Player',
  int totalScore = 0,
  int attendanceScore = 0,
  int winScore = 0,
  int accumulatedScore = 0,
  double seasonTotalWins = 0.0,
  int seasonTotalGames = 0,
  bool scoreAchieved = false,
}) async {
  await fake.collection('players').doc(playerId).set({
    'name': name,
    'totalScore': totalScore,
    'attendanceScore': attendanceScore,
    'winScore': winScore,
    'accumulatedScore': accumulatedScore,
    'seasonTotalWins': seasonTotalWins,
    'seasonTotalGames': seasonTotalGames,
    'scoreAchieved': scoreAchieved,
  });
  await fake.collection('playerRecords').doc(playerId).set({'records': []});
}

PlayerModel _makeModel(FakeFirebaseFirestore fake, String playerId,
    Map<String, dynamic> data) {
  return PlayerModel.fromFireStore(playerId, {
    'name': data['name'] ?? 'Player',
    'totalScore': data['totalScore'] ?? 0,
    'attendanceScore': data['attendanceScore'] ?? 0,
    'winScore': data['winScore'] ?? 0,
    'accumulatedScore': data['accumulatedScore'] ?? 0,
    'seasonTotalWins': (data['seasonTotalWins'] ?? 0.0),
    'seasonTotalGames': data['seasonTotalGames'] ?? 0,
    'scoreAchieved': data['scoreAchieved'] ?? false,
  });
}

void main() {
  late FakeFirebaseFirestore fake;
  late FireStoreApi api;

  setUp(() {
    fake = FakeFirebaseFirestore();
    api = FireStoreApi(fake as FirebaseFirestore);
  });

  // ─────────────────────────────────────────────
  // updatePlayerRecords
  // ─────────────────────────────────────────────
  group('updatePlayerRecords', () {
    test('참석 선수: playerRecords에 기록이 저장되고 player 점수가 증가한다', () async {
      await _seedPlayer(fake, 'p1', name: 'LeBron');
      final model = _makeModel(fake, 'p1', {'name': 'LeBron'});
      final input = _makeInput(model,
          attendanceScore: 15, totalGames: '5', winGames: '3', winScore: '10');

      await api.updatePlayerRecords('2025-06-01', [input]);

      // playerRecords 확인
      final recordDoc =
          await fake.collection('playerRecords').doc('p1').get();
      final records = recordDoc.data()!['records'] as List;
      expect(records.length, 1);
      expect(records[0]['date'], '2025-06-01');
      expect(records[0]['attendanceScore'], 15);
      expect(records[0]['winScore'], 10);
      expect(records[0]['totalGames'], 5);

      // player 점수 누적 확인
      final playerDoc = await fake.collection('players').doc('p1').get();
      final d = playerDoc.data()!;
      expect(d['totalScore'], 25);        // 15 + 10
      expect(d['attendanceScore'], 15);
      expect(d['winScore'], 10);
      expect(d['seasonTotalGames'], 5);
      expect(d['accumulatedScore'], 25);
    });

    test('결석 선수(attendanceScore=0): 모든 값이 0으로 저장된다', () async {
      await _seedPlayer(fake, 'p1', name: 'Bench');
      final model = _makeModel(fake, 'p1', {'name': 'Bench'});
      final input = _makeInput(model,
          attendanceScore: 0, totalGames: '0', winGames: '0', winScore: '0');

      await api.updatePlayerRecords('2025-06-01', [input]);

      final recordDoc =
          await fake.collection('playerRecords').doc('p1').get();
      final records = recordDoc.data()!['records'] as List;
      expect(records.length, 1);
      expect(records[0]['attendanceScore'], 0);
      expect(records[0]['winScore'], 0);

      final playerDoc = await fake.collection('players').doc('p1').get();
      expect(playerDoc.data()!['totalScore'], 0);
    });

    test('같은 날짜 재저장: 기록이 추가되지 않고 덮어쓰기(upsert)된다', () async {
      await _seedPlayer(fake, 'p1', name: 'Jordan');
      final model = _makeModel(fake, 'p1', {'name': 'Jordan'});

      final input1 = _makeInput(model,
          attendanceScore: 15, totalGames: '4', winGames: '2', winScore: '5');
      await api.updatePlayerRecords('2025-06-01', [input1]);

      // 같은 날짜로 다시 저장 (removeRecordFromDate 후 재저장하는 흐름과 동일)
      await fake.collection('playerRecords').doc('p1').set({'records': []});
      final model2 = _makeModel(fake, 'p1', {'name': 'Jordan'});
      final input2 = _makeInput(model2,
          attendanceScore: 15, totalGames: '6', winGames: '4', winScore: '8');
      await api.updatePlayerRecords('2025-06-01', [input2]);

      final recordDoc =
          await fake.collection('playerRecords').doc('p1').get();
      final records = recordDoc.data()!['records'] as List;
      // 기록이 1개만 있어야 함
      expect(records.length, 1);
      expect(records[0]['totalGames'], 6);
      expect(records[0]['winScore'], 8);
    });

    test('여러 선수 동시 저장: 모든 선수 기록이 batch로 저장된다', () async {
      await _seedPlayer(fake, 'p1', name: 'Curry');
      await _seedPlayer(fake, 'p2', name: 'Durant');

      final m1 = _makeModel(fake, 'p1', {'name': 'Curry'});
      final m2 = _makeModel(fake, 'p2', {'name': 'Durant'});

      final inputs = [
        _makeInput(m1,
            attendanceScore: 15, totalGames: '4', winGames: '3', winScore: '6'),
        _makeInput(m2,
            attendanceScore: 10, totalGames: '4', winGames: '1', winScore: '2'),
      ];

      await api.updatePlayerRecords('2025-06-02', inputs);

      final r1 = await fake.collection('playerRecords').doc('p1').get();
      final r2 = await fake.collection('playerRecords').doc('p2').get();
      expect((r1.data()!['records'] as List).length, 1);
      expect((r2.data()!['records'] as List).length, 1);

      final p1 = await fake.collection('players').doc('p1').get();
      final p2 = await fake.collection('players').doc('p2').get();
      expect(p1.data()!['totalScore'], 21); // 15+6
      expect(p2.data()!['totalScore'], 12); // 10+2
    });

    test('milestone 300 돌파 시 scoreAchieved가 true로 설정된다', () async {
      // accumulatedScore 290, 이번에 15점 추가 → 305 (300 돌파)
      await _seedPlayer(fake, 'p1', name: 'MVP', accumulatedScore: 290);
      final model = _makeModel(
          fake, 'p1', {'name': 'MVP', 'accumulatedScore': 290});
      final input = _makeInput(model,
          attendanceScore: 15, totalGames: '0', winGames: '0', winScore: '0');

      await api.updatePlayerRecords('2025-06-01', [input]);

      final playerDoc = await fake.collection('players').doc('p1').get();
      expect(playerDoc.data()!['scoreAchieved'], true);
    });

    test('milestone 미돌파 시 scoreAchieved는 false로 유지된다', () async {
      // accumulatedScore 100, 이번에 15점 → 115 (300 미달)
      await _seedPlayer(fake, 'p1', name: 'Rookie', accumulatedScore: 100);
      final model = _makeModel(
          fake, 'p1', {'name': 'Rookie', 'accumulatedScore': 100});
      final input = _makeInput(model,
          attendanceScore: 15, totalGames: '0', winGames: '0', winScore: '0');

      await api.updatePlayerRecords('2025-06-01', [input]);

      final playerDoc = await fake.collection('players').doc('p1').get();
      expect(playerDoc.data()!['scoreAchieved'], false);
    });
  });

  // ─────────────────────────────────────────────
  // removeRecordFromDate
  // ─────────────────────────────────────────────
  group('removeRecordFromDate', () {
    test('해당 날짜 기록 삭제 후 player 점수가 차감된다', () async {
      await _seedPlayer(fake, 'p1',
          name: 'Kobe',
          totalScore: 25,
          attendanceScore: 15,
          winScore: 10,
          accumulatedScore: 25,
          seasonTotalWins: 3,
          seasonTotalGames: 5);

      // 기존 기록 세팅
      await fake.collection('playerRecords').doc('p1').set({
        'records': [
          {
            'date': '2025-06-01',
            'attendanceScore': 15,
            'winScore': 10,
            'winningGames': 3.0,
            'totalGames': 5,
          }
        ]
      });

      await api.removeRecordFromDate('2025-06-01');

      // 기록 삭제 확인
      final recordDoc =
          await fake.collection('playerRecords').doc('p1').get();
      expect((recordDoc.data()!['records'] as List).isEmpty, true);

      // 점수 차감 확인
      final playerDoc = await fake.collection('players').doc('p1').get();
      final d = playerDoc.data()!;
      expect(d['totalScore'], 0);
      expect(d['attendanceScore'], 0);
      expect(d['winScore'], 0);
      expect(d['accumulatedScore'], 0);
    });

    test('해당 날짜 기록이 없는 선수는 점수 변화 없다', () async {
      await _seedPlayer(fake, 'p1',
          name: 'Shaq', totalScore: 100, accumulatedScore: 100);
      await fake.collection('playerRecords').doc('p1').set({
        'records': [
          {
            'date': '2025-05-01', // 다른 날짜
            'attendanceScore': 10,
            'winScore': 5,
            'winningGames': 2.0,
            'totalGames': 3,
          }
        ]
      });

      await api.removeRecordFromDate('2025-06-01');

      final playerDoc = await fake.collection('players').doc('p1').get();
      expect(playerDoc.data()!['totalScore'], 100); // 변화 없어야 함

      final recordDoc =
          await fake.collection('playerRecords').doc('p1').get();
      expect((recordDoc.data()!['records'] as List).length, 1); // 다른 날짜 기록은 유지
    });

    test('여러 선수 중 해당 날짜 기록 있는 선수만 차감된다', () async {
      await _seedPlayer(fake, 'p1',
          name: 'A', totalScore: 25, accumulatedScore: 25);
      await _seedPlayer(fake, 'p2',
          name: 'B', totalScore: 50, accumulatedScore: 50);

      await fake.collection('playerRecords').doc('p1').set({
        'records': [
          {
            'date': '2025-06-01',
            'attendanceScore': 15,
            'winScore': 10,
            'winningGames': 2.0,
            'totalGames': 4,
          }
        ]
      });
      // p2는 해당 날짜 기록 없음
      await fake.collection('playerRecords').doc('p2').set({
        'records': [
          {
            'date': '2025-05-20',
            'attendanceScore': 15,
            'winScore': 10,
            'winningGames': 3.0,
            'totalGames': 5,
          }
        ]
      });

      await api.removeRecordFromDate('2025-06-01');

      final p1 = await fake.collection('players').doc('p1').get();
      final p2 = await fake.collection('players').doc('p2').get();
      expect(p1.data()!['totalScore'], 0);   // 차감됨
      expect(p2.data()!['totalScore'], 50);  // 변화 없음
    });
  });
}
