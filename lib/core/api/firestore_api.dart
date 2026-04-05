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

  // ─────────────────────────────────────────────
  // 선수 조회
  // ─────────────────────────────────────────────

  Future<QuerySnapshot<Map<String, dynamic>>> getPlayers() async {
    return _firestore.collection('players').get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getPlayersFromYear(
      String year) async {
    return _firestore
        .collection('seasons')
        .doc(year)
        .collection('players')
        .get();
  }

  Future<List<String>> getSeasons() async {
    final snapshot = await _firestore.collection('seasons').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // ─────────────────────────────────────────────
  // 선수 추가 / 삭제 / 상태 변경
  // ─────────────────────────────────────────────

  Future<void> addPlayer(String name) async {
    // 동일 이름 중복 체크 (활성/휴면 포함)
    final existing = await _firestore
        .collection('players')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final status = existing.docs.first.data()['status'] ?? 'active';
      final hint = status == 'inactive' ? ' (현재 휴면 상태)' : '';
      throw Exception('이미 등록된 선수입니다: $name$hint');
    }

    final batch = _firestore.batch();
    final playerRef = _firestore.collection('players').doc();
    final recordsRef =
        _firestore.collection('playerRecords').doc(playerRef.id);

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
    batch.set(recordsRef, {'records': []});
    await batch.commit();
  }

  /// 선수 완전 삭제 (복구 불가)
  Future<void> removePlayer(String playerId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('players').doc(playerId));
    batch.delete(_firestore.collection('playerRecords').doc(playerId));
    await batch.commit();
  }

  /// 선수 비활성화 (휴면) - status: inactive
  Future<void> archivePlayer(String playerId) async {
    await _firestore
        .collection('players')
        .doc(playerId)
        .update({'status': 'inactive'});
  }

  /// 비활성 선수 복구 - status: active
  Future<void> restorePlayer(String playerId) async {
    await _firestore
        .collection('players')
        .doc(playerId)
        .update({'status': 'active'});
  }

  // ─────────────────────────────────────────────
  // 기록 조회
  // ─────────────────────────────────────────────

  Future<List> getPlayerRecords(String playerId) async {
    final doc =
        await _firestore.collection('playerRecords').doc(playerId).get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null || !data.containsKey('records')) return [];
    return data['records'];
  }

  Future<List> getPlayerRecordsFromYear(String year, String playerId) async {
    final doc = await _firestore
        .collection('seasons')
        .doc(year)
        .collection('playerRecords')
        .doc(playerId)
        .get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null || !data.containsKey('records')) return [];
    return data['records'];
  }

  // ─────────────────────────────────────────────
  // 기록 저장 / 삭제
  // ─────────────────────────────────────────────

  /// 선수별 기록 병렬 조회 후 batch 저장 (Future.wait으로 성능 최적화)
  Future<void> updatePlayerRecords(
    String recordDate,
    List<PlayerGameInput> playerInputs,
  ) async {
    final batch = _firestore.batch();

    final recordRefs = playerInputs
        .map((p) => _firestore.collection('playerRecords').doc(p.playerId))
        .toList();

    final snapshots =
        await Future.wait(recordRefs.map((ref) => ref.get()));

    for (int i = 0; i < playerInputs.length; i++) {
      final input = playerInputs[i];
      final recordRef = recordRefs[i];
      final playerRef =
          _firestore.collection('players').doc(input.playerId);

      final recordModel = RecordModel(
        date: recordDate,
        attendanceScore: input.attendanceScore,
        winScore: input.winScore,
        winningGames: input.winGames.toDouble(),
        totalGames: input.totalGames,
      );

      List<dynamic> records = [];
      final snapshot = snapshots[i];
      if (snapshot.exists && snapshot.data() != null) {
        records = List.from(snapshot.data()!['records'] ?? []);
      }

      final idx = records.indexWhere((r) => r['date'] == recordDate);
      if (idx >= 0) {
        records[idx] = recordModel.toJson();
      } else {
        records.add(recordModel.toJson());
      }

      batch.set(recordRef, {'records': records});
      batch.update(playerRef, {
        'totalScore': FieldValue.increment(input.attendanceScore + input.winScore),
        'attendanceScore': FieldValue.increment(input.attendanceScore),
        'winScore': FieldValue.increment(input.winScore),
        'seasonTotalWins': FieldValue.increment(input.winGames),
        'seasonTotalGames': FieldValue.increment(input.totalGames),
        'accumulatedScore':
            FieldValue.increment(input.attendanceScore + input.winScore),
        'scoreAchieved': isMilestonePassed(
          input.player.accumulatedScore,
          input.player.accumulatedScore + input.attendanceScore + input.winScore,
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

  Future<void> removeRecordFromDate(String targetDate) async {
    // players / playerRecords 병렬 조회
    final [recordsSnapshot, playersSnapshot] = await Future.wait([
      _firestore.collection('playerRecords').get(),
      _firestore.collection('players').get(),
    ]);

    // 현재 누적점수 맵 구성
    final accumulatedMap = {
      for (final doc in playersSnapshot.docs)
        doc.id: (doc.data()['accumulatedScore'] as num? ?? 0).toInt()
    };

    final playersRef = _firestore.collection('players');
    final batch = _firestore.batch();

    for (final doc in recordsSnapshot.docs) {
      final playerId = doc.id;
      final records = List<dynamic>.from(doc.data()['records'] ?? []);
      final toRemove =
          records.where((r) => r['date'] == targetDate).toList();

      records.removeWhere((r) => r['date'] == targetDate);
      batch.set(doc.reference, {'records': records});

      if (toRemove.isNotEmpty) {
        final r = toRemove.first;
        final removedScore =
            (r['attendanceScore'] as num? ?? 0).toInt() +
            (r['winScore'] as num? ?? 0).toInt();
        final newAccumulated =
            (accumulatedMap[playerId] ?? 0) - removedScore;

        batch.update(playersRef.doc(playerId), {
          'totalScore': FieldValue.increment(
              -(r['attendanceScore'] ?? 0) - (r['winScore'] ?? 0)),
          'attendanceScore':
              FieldValue.increment(-(r['attendanceScore'] ?? 0)),
          'winScore': FieldValue.increment(-(r['winScore'] ?? 0)),
          'seasonTotalWins':
              FieldValue.increment(-(r['winningGames'] ?? 0)),
          'seasonTotalGames':
              FieldValue.increment(-(r['totalGames'] ?? 0)),
          'accumulatedScore': FieldValue.increment(-removedScore),
          // 삭제 후 누적점수가 여전히 마일스톤(300) 이상이면 scoreAchieved 유지
          'scoreAchieved': newAccumulated >= 300,
        });
      }
    }

    await batch.commit();
  }

  Future<bool> hasAnyRealRecordOnDate(String date) async {
    final snapshot = await _firestore.collection('playerRecords').get();

    for (final doc in snapshot.docs) {
      final records = List.from(doc.data()['records'] ?? []);
      for (final record in records) {
        if (record['date'] == date) {
          if ((record['attendanceScore'] ?? 0) != 0 ||
              (record['winScore'] ?? 0) != 0 ||
              (record['winningGames'] ?? 0) != 0 ||
              (record['totalGames'] ?? 0) != 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // 시즌 아카이브
  // ─────────────────────────────────────────────

  /// 시즌 종료 시 데이터를 seasons/{seasonName}/으로 백업하고 현재 점수 초기화.
  /// players / playerRecords를 병렬 조회하여 성능 최적화.
  Future<void> archiveAndResetSeason(String seasonName) async {
    final [playersSnapshot, recordsSnapshot] = await Future.wait([
      _firestore.collection('players').get(),
      _firestore.collection('playerRecords').get(),
    ]);

    final batch = _firestore.batch();

    for (final doc in playersSnapshot.docs) {
      final playerId = doc.id;

      batch.set(
        _firestore
            .collection('seasons')
            .doc(seasonName)
            .collection('players')
            .doc(playerId),
        doc.data(),
      );

      batch.update(_firestore.collection('players').doc(playerId), {
        'totalScore': 0,
        'attendanceScore': 0,
        'winScore': 0,
        'seasonTotalGames': 0,
        'seasonTotalWins': 0.0,
        'scoreAchieved': false,
      });
    }

    for (final doc in recordsSnapshot.docs) {
      final playerId = doc.id;

      batch.set(
        _firestore
            .collection('seasons')
            .doc(seasonName)
            .collection('playerRecords')
            .doc(playerId),
        doc.data(),
      );

      batch.set(
        _firestore.collection('playerRecords').doc(playerId),
        {'records': []},
      );
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // 유틸
  // ─────────────────────────────────────────────

  bool isMilestonePassed(int before, int after, {int milestone = 300}) {
    return (before ~/ milestone) < (after ~/ milestone);
  }
}

@riverpod
FireStoreApi fireStoreApi(Ref ref) {
  return FireStoreApi(FirebaseFirestore.instance);
}
