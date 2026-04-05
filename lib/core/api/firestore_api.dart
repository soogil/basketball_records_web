import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iggys_point/models/player_model.dart';
import 'package:iggys_point/models/record_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_api.g.dart';

class FireStoreApi {
  FireStoreApi(this._firestore);

  final FirebaseFirestore _firestore;

  Future uploadPlayersToFireStore() async {
    // final playersCollection = _firestore.collection('players');
    // final querySnapshot = await playersCollection.get();
    //
    // for (var doc in querySnapshot.docs) {
    //   await doc.reference.update({'scoreAchieved': false});
    // }

    //backup data download
    // final playersRef = _firestore.collection('players');
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
    //   final firestore = _firestore;
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
    return await _firestore.collection('players').get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPlayersFromYear(
      String year) async {
    return await _firestore
        .collection('seasons')
        .doc(year)
        .collection('players')
        .get();
  }

  Future<List<String>> getSeasons() async {
    final snapshot = await _firestore.collection('seasons').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List> getPlayerRecords(String playerId) async {
    final docSnapshot = await _firestore
        .collection('playerRecords')
        .doc(playerId)
        .get();

    if (!docSnapshot.exists) return [];
    final data = docSnapshot.data();
    if (data == null || !data.containsKey('records')) return [];
    return data['records'];
  }

  Future<List> getPlayerRecordsFromYear(String year, String playerId) async {
    final docSnapshot = await _firestore
        .collection('seasons')
        .doc(year)
        .collection('playerRecords')
        .doc(playerId)
        .get();

    if (!docSnapshot.exists) return [];
    final data = docSnapshot.data();
    if (data == null || !data.containsKey('records')) return [];
    return data['records'];
  }

  Future<void> addPlayer(String name) async {
    final batch = _firestore.batch();
    final playerRef = _firestore.collection('players').doc();
    final playerRecordsRef = _firestore.collection('playerRecords').doc(playerRef.id);
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
      status: 'active',
    );

    batch.set(playerRef, player.toJson());
    batch.set(playerRecordsRef, {'records': []});
    await batch.commit();
  }

  Future<void> removePlayer(String playerId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('players').doc(playerId));
    batch.delete(_firestore.collection('playerRecords').doc(playerId));
    await batch.commit();
  }

  /// 선수를 비활성화(휴면) 처리 - status 필드만 업데이트
  Future<void> archivePlayer(String playerId) async {
    await _firestore
        .collection('players')
        .doc(playerId)
        .update({'status': 'inactive'});
  }

  /// 비활성화된 선수를 활성 복구 - status 필드만 업데이트
  Future<void> restorePlayer(String playerId) async {
    await _firestore
        .collection('players')
        .doc(playerId)
        .update({'status': 'active'});
  }

  /// 선수별 기록을 병렬 조회한 뒤 batch 업데이트로 저장.
  /// 기존 직렬 읽기(for loop await)를 Future.wait로 병렬화하여 성능 개선.
  Future<void> updatePlayerRecords(
    String recordDate,
    List<PlayerGameInput> playerInputs,
  ) async {
    final batch = _firestore.batch();

    // 1. 모든 선수 기록 병렬 조회
    final recordRefs = playerInputs
        .map((p) => _firestore.collection('playerRecords').doc(p.playerId))
        .toList();

    final snapshots = await Future.wait(recordRefs.map((ref) => ref.get()));

    // 2. 각 선수 처리
    for (int i = 0; i < playerInputs.length; i++) {
      final playerInput = playerInputs[i];
      final recordRef = recordRefs[i];
      final playerRef =
          _firestore.collection('players').doc(playerInput.playerId);
      final int attendanceScore = playerInput.attendanceScore;
      final int winScore = playerInput.winScore;

      final recordModel = RecordModel(
        date: recordDate,
        attendanceScore: attendanceScore,
        winScore: winScore,
        winningGames: playerInput.winGames.toDouble(),
        totalGames: playerInput.totalGames,
      );

      List<dynamic> playerRecords = [];
      final snapshot = snapshots[i];
      if (snapshot.exists && snapshot.data() != null) {
        playerRecords = List.from(snapshot.data()!['records'] ?? []);
      }

      final idx = playerRecords.indexWhere((r) => r['date'] == recordDate);
      if (idx >= 0) {
        playerRecords[idx] = recordModel.toJson();
      } else {
        playerRecords.add(recordModel.toJson());
      }

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
          playerInput.player.accumulatedScore + attendanceScore + winScore,
        ),
      });
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Batch update failed: $e');
      rethrow;
    }
  }

  bool _isMilestonePassed(int before, int after, {int milestone = 300}) {
    return (before ~/ milestone) < (after ~/ milestone);
  }

  Future<void> removeRecordFromDate(String targetDate) async {
    final playerRecordsRef = _firestore.collection('playerRecords');
    final playersRef = _firestore.collection('players');

    final snapshot = await playerRecordsRef.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final playerId = doc.id;
      final data = doc.data();
      List<dynamic> records = List.from(data['records'] ?? []);

      final toRemove =
          records.where((r) => r['date'] == targetDate).toList();
      records.removeWhere((r) => r['date'] == targetDate);

      batch.set(doc.reference, {'records': records});

      if (toRemove.isNotEmpty) {
        final r = toRemove.first;
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
    final snapshot =
        await _firestore.collection('playerRecords').get();

    for (final doc in snapshot.docs) {
      final records = List.from(doc.data()['records'] ?? []);
      for (final record in records) {
        if (record['date'] == date) {
          final attendance = record['attendanceScore'] ?? 0;
          final score = record['winScore'] ?? 0;
          final win = record['winningGames'] ?? 0;
          final games = record['totalGames'] ?? 0;
          if (attendance != 0 || score != 0 || win != 0 || games != 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> archiveAndResetSeason(String seasonName) async {
    final batch = _firestore.batch();

    final playersSnapshot =
        await _firestore.collection('players').get();
    final recordsSnapshot =
        await _firestore.collection('playerRecords').get();

    for (var doc in playersSnapshot.docs) {
      final data = doc.data();
      final playerId = doc.id;

      final archiveRef = _firestore
          .collection('seasons')
          .doc(seasonName)
          .collection('players')
          .doc(playerId);
      batch.set(archiveRef, data);

      final playerRef = _firestore.collection('players').doc(playerId);
      batch.update(playerRef, {
        'totalScore': 0,
        'attendanceScore': 0,
        'winScore': 0,
        'seasonTotalGames': 0,
        'seasonTotalWins': 0.0,
        'scoreAchieved': false,
      });
    }

    for (var doc in recordsSnapshot.docs) {
      final data = doc.data();
      final playerId = doc.id;

      final archiveRecordRef = _firestore
          .collection('seasons')
          .doc(seasonName)
          .collection('playerRecords')
          .doc(playerId);
      batch.set(archiveRecordRef, data);

      final recordRef =
          _firestore.collection('playerRecords').doc(playerId);
      batch.set(recordRef, {'records': []});
    }

    await batch.commit();
  }

  bool isMilestonePassed(int before, int after, {int milestone = 300}) {
    return (before ~/ milestone) < (after ~/ milestone);
  }
}

@riverpod
FireStoreApi fireStoreApi(Ref ref) {
  return FireStoreApi(FirebaseFirestore.instance);
}
