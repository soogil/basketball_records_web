import 'package:flutter/foundation.dart';
import 'package:iggys_point/feature/main/data/models/player_model.dart';
import 'package:iggys_point/feature/record/data/models/record_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/feature/record/presentation/record_add_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_api.g.dart';


class FireStoreApi {

  Future uploadPlayersToFireStore() async {
    // final playersCollection = FirebaseFirestore.instance.collection('players');
    // final querySnapshot = await playersCollection.get();
    //
    // for (var doc in querySnapshot.docs) {
    //   await doc.reference.update({'scoreAchieved': false});
    // }

    //backup data download
    // final playersRef = FirebaseFirestore.instance.collection('players');
    // final snapshot = await playersRef.get();
    //
    // Map<String, dynamic> allRecords = {};
    // for (final doc in snapshot.docs) {
    //   allRecords[doc.id] = doc.data();
    // }
    //
    // String jsonString = jsonEncode(allRecords);
    //
    // final bytes = utf8.encode(jsonString);
    // final blob = html.Blob([bytes]);
    // final url = html.Url.createObjectUrlFromBlob(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute("download", "players_backup.json")
    //   ..click();
    // html.Url.revokeObjectUrl(url);

    //upload backup Data
    //   final playersJson = await rootBundle.loadString('assets/players_backup.json');
    //   final playerRecordsJson = await rootBundle.loadString('assets/player_records_backup.json');
    //   final players = jsonDecode(playersJson) as Map<String, dynamic>;
    //   final records = jsonDecode(playerRecordsJson) as Map<String, dynamic>;
    //
    //   final firestore = FirebaseFirestore.instance;
    //
    //   // players (id = docId, value = fields)
    //   for (final entry in players.entries) {
    //     final id = entry.key;
    //     final data = entry.value as Map<String, dynamic>;
    //     await firestore.collection('players').doc(id).set(data);
    //   }
    //
    //   // playerRecords (id = docId, value = { records: [...] })
    //   for (final entry in records.entries) {
    //     final id = entry.key;
    //     final data = entry.value as Map<String, dynamic>;
    //     await firestore.collection('playerRecords').doc(id).set(data);
    //   }
    //
    //   print('All players and records imported!');
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPlayers() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('players')
        .get();

    return querySnapshot;
  }

  Future<List> getPlayerRecords(String playerId) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('playerRecords')
        .doc(playerId)
        .get();

    if (!docSnapshot.exists) return [];


    final data = docSnapshot.data();
    if (data == null || !data.containsKey('records')) return [];

    return data['records'];
  }

  Future<void> addPlayer(String name) async {
    final fireStore = FirebaseFirestore.instance;
    final batch = fireStore.batch();
    final playerRef = FirebaseFirestore.instance.collection('players').doc();
    final playerRecordsRef = FirebaseFirestore.instance.collection('playerRecords').doc();
    final player = PlayerModel(
      id: playerRef.id,
      name: name,
      totalScore: 0,
      attendanceScore: 0,
      accumulatedScore: 0,
      winScore: 0,
      seasonTotalGames: 0,
      seasonTotalWins: 0.0,
      scoreAchieved: false,
    );

    batch.set(playerRef, player.toJson());
    batch.set(playerRecordsRef, {'records': []});

    await batch.commit();
  }

  Future<void> removePlayer(String playerId) async {
    final fireStore = FirebaseFirestore.instance;
    final batch = fireStore.batch();

    final playerRef = fireStore.collection('players').doc(playerId);
    final playerRecordsRef = fireStore.collection('playerRecords').doc(playerId);

    batch.delete(playerRef);
    batch.delete(playerRecordsRef);

    await batch.commit();
  }

  Future<void> updatePlayerRecords(
      String recordDate,
      List<PlayerGameInput> playerInputs) async {
    final fireStore = FirebaseFirestore.instance;
    final batch = fireStore.batch();

    for (final playerInput in playerInputs) {
      final playerId = playerInput.playerId;
      final recordRef = fireStore.collection('playerRecords').doc(playerId);
      final playerRef = fireStore.collection('players').doc(playerId);
      final int attendanceScore = playerInput.attendanceScore;
      final int winScore = playerInput.winScore;

      // 1. RecordModel 생성 (각 선수의 해당 날짜 기록)
      final recordModel = RecordModel(
        date: recordDate,
        attendanceScore: attendanceScore,
        winScore: winScore,
        winningGames: playerInput.winGames.toDouble(),
        totalGames: playerInput.totalGames.toInt(),
      );

      // 2. 기존 기록 읽기 (해당 선수)
      final snapshot = await recordRef.get();
      List<dynamic> playerRecords = [];
      if (snapshot.exists && snapshot.data() != null) {
        playerRecords = List.from(snapshot.data()!['records'] ?? []);
      }
      final idx = playerRecords.indexWhere((r) => r['date'] == recordDate);
      if (idx >= 0) {
        playerRecords[idx] = recordModel.toJson();
      } else {
        playerRecords.add(recordModel.toJson());
      }

      // 3. batch로 기록/누적치 갱신 추가
      batch.set(recordRef, {'records': playerRecords});
      batch.update(playerRef, {
        'totalScore': FieldValue.increment(attendanceScore + winScore),
        'attendanceScore': FieldValue.increment(attendanceScore),
        'winScore': FieldValue.increment(winScore),
        'seasonTotalWins': FieldValue.increment(playerInput.winGames),
        'seasonTotalGames': FieldValue.increment(playerInput.totalGames),
        'accumulatedScore': FieldValue.increment(attendanceScore + winScore),
        'scoreAchieved': _isMilestonePassed(
            playerInput.player.accumulatedScore,
            playerInput.player.accumulatedScore + attendanceScore + winScore),
      });
    }

    // 4. batch 커밋: 한 명이라도 실패시 모두 롤백
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Batch update failed: $e');
      rethrow;
    }
  }

  bool _isMilestonePassed(int before, int after, {int milestone = 300}) {
    int beforeSection = before ~/ milestone;
    int afterSection = after ~/ milestone;
    return beforeSection < afterSection;
  }

  Future<void> removeRecordFromDate(String targetDate) async {
    final firestore = FirebaseFirestore.instance;
    final playerRecordsRef = firestore.collection('playerRecords');
    final playersRef = firestore.collection('players');

    final snapshot = await playerRecordsRef.get();
    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      final playerId = doc.id;
      final data = doc.data();
      List<dynamic> records = List.from(data['records'] ?? []);

      // 삭제 대상 기록 추출
      final toRemove = records.where((r) => r['date'] == targetDate).toList();

      // 해당 날짜 기록만 삭제
      records.removeWhere((r) => r['date'] == targetDate);

      // batch로 playerRecords 갱신
      batch.set(doc.reference, {'records': records});

      // 만약 해당 날짜 기록이 존재하면 players의 누적값에서 빼기
      if (toRemove.isNotEmpty) {
        final r = toRemove.first; // 한 날짜에 하나만 있다고 가정
        batch.update(playersRef.doc(playerId), {
          'totalScore': FieldValue.increment(-(r['attendanceScore'] ?? 0) - (r['winScore'] ?? 0)),
          'attendanceScore': FieldValue.increment(-(r['attendanceScore'] ?? 0)),
          'winScore': FieldValue.increment(-(r['winScore'] ?? 0)),
          'seasonTotalWins': FieldValue.increment(-(r['winningGames'] ?? 0)),
          'seasonTotalGames': FieldValue.increment(-(r['totalGames'] ?? 0)),
          'accumulatedScore': FieldValue.increment(-(r['attendanceScore'] ?? 0) - (r['winScore'] ?? 0)),
          'scoreAchieved': false,
        });
      }
    }

    await batch.commit();
  }

  Future<bool> hasAnyRealRecordOnDate(String date) async {
    final playerRecordsRef = FirebaseFirestore.instance.collection('playerRecords');
    final snapshot = await playerRecordsRef.get();

    for (final doc in snapshot.docs) {
      final records = List.from(doc.data()['records'] ?? []);
      for (final record in records) {
        if (record['date'] == date) {
          // 하나라도 0이 아니면 true
          final attendance = record['attendanceScore'] ?? 0;
          final score = record['winScore'] ?? 0;
          final win = record['winningGames'] ?? 0;
          final games = record['totalGames'] ?? 0;
          if (attendance != 0 || score != 0 || win != 0 || games != 0) {
            return true; // 하나라도 0이 아니면 "기록 있음"
          }
        }
      }
    }
    return false; // 모두 0이거나, date자체가 없는 경우
  }
}

@riverpod
FireStoreApi fireStoreApi(Ref ref) {
  return FireStoreApi();
}