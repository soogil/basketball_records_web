// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/core/api/firestore_api.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('FireStoreApi - pure logic', () {
    test('isMilestonePassed: 299 -> 300 은 true', () {
      final api = FireStoreApi(FakeFirebaseFirestore() as FirebaseFirestore);
      expect(api.isMilestonePassed(299, 300), true);
    });

    test('isMilestonePassed: 300 -> 599 은 false', () {
      final api = FireStoreApi(FakeFirebaseFirestore() as FirebaseFirestore);
      expect(api.isMilestonePassed(300, 599), false);
    });

    test('isMilestonePassed: 300 -> 600 은 true', () {
      final api = FireStoreApi(FakeFirebaseFirestore() as FirebaseFirestore);
      expect(api.isMilestonePassed(300, 600), true);
    });
  });

  group('FireStoreApi - firestore behavior', () {
    late FakeFirebaseFirestore fake;
    late FireStoreApi api;

    setUp(() {
      fake = FakeFirebaseFirestore();
      api = FireStoreApi(fake as FirebaseFirestore);
    });

    test('addPlayer: players와 playerRecords가 같은 id로 생성된다', () async {
      await api.addPlayer('Jordan');

      final playersSnap = await fake.collection('players').get();
      expect(playersSnap.docs.length, 1);

      final playerId = playersSnap.docs.first.id;

      final recordDoc = await fake.collection('playerRecords').doc(playerId).get();
      expect(recordDoc.exists, true);
      expect(recordDoc.data()!['records'], isA<List>());
      expect((recordDoc.data()!['records'] as List).length, 0);
    });

    test('removePlayer: players와 playerRecords가 같이 삭제된다', () async {
      await api.addPlayer('Curry');

      final playersSnap = await fake.collection('players').get();
      final playerId = playersSnap.docs.first.id;

      await api.removePlayer(playerId);

      final playerDoc = await fake.collection('players').doc(playerId).get();
      final recordDoc = await fake.collection('playerRecords').doc(playerId).get();

      expect(playerDoc.exists, false);
      expect(recordDoc.exists, false);
    });

    test('hasAnyRealRecordOnDate: 날짜 기록이 전부 0이면 false', () async {
      // playerRecords 문서 하나 만들어서 records 넣기
      await fake.collection('playerRecords').doc('p1').set({
        'records': [
          {
            'date': '2025-12-15',
            'attendanceScore': 0,
            'winScore': 0,
            'winningGames': 0,
            'totalGames': 0,
          }
        ]
      });

      final result = await api.hasAnyRealRecordOnDate('2025-12-15');
      expect(result, false);
    });

    test('hasAnyRealRecordOnDate: 하나라도 0이 아니면 true', () async {
      await fake.collection('playerRecords').doc('p1').set({
        'records': [
          {
            'date': '2025-12-15',
            'attendanceScore': 10,
            'winScore': 0,
            'winningGames': 0,
            'totalGames': 0,
          }
        ]
      });

      final result = await api.hasAnyRealRecordOnDate('2025-12-15');
      expect(result, true);
    });
  });

  group('Riverpod provider override test', () {
    test('fireStoreApi provider를 FakeFirestore로 override 가능', () async {
      final fake = FakeFirebaseFirestore();

      final container = ProviderContainer(
        overrides: [
          fireStoreApiProvider.overrideWith((ref) => FireStoreApi(fake as FirebaseFirestore)),
        ],
      );
      addTearDown(container.dispose);

      final api = container.read(fireStoreApiProvider);

      await api.addPlayer('Kobe');

      final playersSnap = await fake.collection('players').get();
      expect(playersSnap.docs.length, 1);
      expect(playersSnap.docs.first.data()['name'], 'Kobe');
    });
  });

  group('시즌 데이터 초기화 테스트', ()
  {
    late FakeFirebaseFirestore fake;
    late FireStoreApi api;

    setUp(() {
      fake = FakeFirebaseFirestore();
      api = FireStoreApi(fake as FirebaseFirestore);
    });

    test('archiveAndResetSeason: 데이터 백업 후 시즌 점수 초기화, 누적 점수 유지 확인', () async {
      // [1] 초기 데이터 세팅 (2025년 시즌 종료 시점 가정)
      final playerId = 'player_1';

      // 플레이어: 시즌 점수 100점, 누적 점수 1000점
      await fake.collection('players').doc(playerId).set({
        'name': 'Test Player',
        'totalScore': 100,
        'attendanceScore': 50,
        'winScore': 50,
        'seasonTotalWins': 10.0,
        'seasonTotalGames': 20,
        'accumulatedScore': 1000, // 이 값은 유지되어야 함
        'scoreAchieved': true,
      });

      // 기록: 기록이 1개 존재
      await fake.collection('playerRecords').doc(playerId).set({
        'records': [
          {'date': '2025-12-01', 'attendanceScore': 10, 'winScore': 10}
        ]
      });

      // [2] 함수 실행 (2025 시즌 마감)
      // *주의: FireStoreApi 클래스에 archiveAndResetSeason 함수가 추가되어 있어야 합니다.
      await api.archiveAndResetSeason('2025');

      // [3] 검증 (Assertions)

      // 3-1. 백업 확인 (seasons/2025/players)
      final backupSnapshot = await fake
          .collection('seasons')
          .doc('2025')
          .collection('players')
          .doc(playerId)
          .get();

      expect(backupSnapshot.exists, true, reason: '백업 데이터가 생성되어야 함');
      expect(backupSnapshot.data()!['totalScore'], 100,
          reason: '백업된 데이터는 기존 점수(100)를 가지고 있어야 함');

      // 3-2. 초기화 확인 (players)
      final currentSnapshot = await fake.collection('players')
          .doc(playerId)
          .get();

      expect(currentSnapshot.data()!['totalScore'], 0,
          reason: '현재 시즌 점수는 0으로 초기화되어야 함');
      expect(currentSnapshot.data()!['attendanceScore'], 0);
      expect(currentSnapshot.data()!['seasonTotalGames'], 0);

      // ★ 핵심: 누적 점수는 유지되었는지 확인
      expect(currentSnapshot.data()!['accumulatedScore'], 1000,
          reason: '누적 점수는 초기화되지 않고 유지되어야 함');

      // 3-3. 기록 초기화 확인 (playerRecords)
      final recordSnapshot = await fake.collection('playerRecords').doc(
          playerId).get();
      final List records = recordSnapshot.data()!['records'];

      expect(records.isEmpty, true, reason: '현재 시즌의 기록 리스트는 비워져야 함');

      // 3-4. 기록 백업 확인
      final backupRecordSnapshot = await fake
          .collection('seasons')
          .doc('2025')
          .collection('playerRecords')
          .doc(playerId)
          .get();
      final List backupRecords = backupRecordSnapshot.data()!['records'];
      expect(backupRecords.length, 1, reason: '백업된 기록은 그대로 남아있어야 함');
    });
  });
}
