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
}
