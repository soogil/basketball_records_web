import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:iggys_point/core/theme/br_color.dart';

part 'player_model.freezed.dart';
part 'player_model.g.dart';

@freezed
@JsonSerializable()
class PlayerModel with _$PlayerModel {
  PlayerModel({
    required this.id,
    required this.name,
    required this.totalScore,
    required this.attendanceScore,
    required this.accumulatedScore,
    required this.winScore,
    required this.seasonTotalGames,
    required this.seasonTotalWins,
    required this.scoreAchieved,
    this.status = 'active',
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final int totalScore;
  @override
  final int attendanceScore;
  @override
  final int winScore;
  @override
  final double seasonTotalWins;
  @override
  final int seasonTotalGames;
  @override
  final int accumulatedScore;
  @override
  final bool scoreAchieved;
  @override
  final String status;

  factory PlayerModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerModelFromJson(json);

  Map<String, Object?> toJson() => _$PlayerModelToJson(this);

  factory PlayerModel.fromFireStore(
    String id,
    Map<String, dynamic> json,
  ) =>
      PlayerModel(
        id: id,
        name: json['name'] as String,
        totalScore: json['totalScore'] as int,
        attendanceScore: json['attendanceScore'] as int,
        accumulatedScore: json['accumulatedScore'] as int,
        winScore: json['winScore'] as int,
        seasonTotalWins: (json['seasonTotalWins'] as num).toDouble(),
        seasonTotalGames: json['seasonTotalGames'] as int,
        scoreAchieved: json['scoreAchieved'] as bool,
        status: json['status'] as String? ?? 'active',
      );
}

/// 기록 입력 시 선수별 입력 데이터. Presenter와 View 사이를 오가므로 models 레이어에 위치.
class PlayerGameInput {
  final PlayerModel player;
  int attendanceScore;
  final TextEditingController totalGamesController;
  final TextEditingController winGamesController;
  final TextEditingController winScoreController;

  PlayerGameInput({
    required this.player,
    this.attendanceScore = 15,
  })  : totalGamesController = TextEditingController(text: '0'),
        winGamesController = TextEditingController(text: '0'),
        winScoreController = TextEditingController(text: '0');

  int get winScore => int.parse(winScoreController.text);
  int get winGames => int.parse(winGamesController.text);
  int get totalGames => int.parse(totalGamesController.text);
  String get playerId => player.id;
  String get playerName => player.name;

  @override
  String toString() => '이름: ${player.name} 참석: $attendanceScore '
      '게임 수: ${totalGamesController.text} 승리: ${winGamesController.text} 승점: ${winScoreController.text}';
}

class TeamInput {
  final String teamName;
  final List<PlayerGameInput> players;
  TeamInput({required this.teamName, required this.players});
}

class TeamMeta {
  final TextEditingController gamesController;
  final TextEditingController winsController;
  final TextEditingController scoreController;

  TeamMeta()
      : gamesController = TextEditingController(),
        winsController = TextEditingController(),
        scoreController = TextEditingController();

  void dispose() {
    gamesController.dispose();
    winsController.dispose();
    scoreController.dispose();
  }
}

extension PlayerModelPresentation on PlayerModel {
  String valueByColumn(PlayerColumn column, {int? index}) {
    switch (column) {
      case PlayerColumn.rank:
        return index == null ? '0' : '$index';
      case PlayerColumn.name:
        return name;
      case PlayerColumn.winScore:
        return '$winScore점';
      case PlayerColumn.accumulatedScore:
        return '$accumulatedScore점';
      case PlayerColumn.totalScore:
        return '$totalScore점';
      case PlayerColumn.attendanceScore:
        return '$attendanceScore점';
      case PlayerColumn.winRate:
        return seasonTotalGames == 0
            ? '0%'
            : '${((seasonTotalWins / seasonTotalGames) * 100).toStringAsFixed(0)}%';
    }
  }

  Color get accumulatedScoreColor {
    if (accumulatedScore > 1800) return const Color(0xFF5C2FC2);
    if (accumulatedScore > 1500) return const Color(0xFFB33791);
    if (accumulatedScore > 1200) return const Color(0xFF362FD9);
    if (accumulatedScore > 900) return const Color(0xFF40A578);
    if (accumulatedScore > 600) return const Color(0xFFFF7601);
    if (accumulatedScore > 300) return const Color(0xFFE52020);
    return BRColors.black;
  }

  double get winRate =>
      seasonTotalGames == 0 ? 0 : (seasonTotalWins / seasonTotalGames) * 100;
}

/// 누적 점수 티어 정보
class TierInfo {
  const TierInfo({
    required this.name,
    required this.badgeColor,
    required this.barColor,
  });
  final String name;
  final Color badgeColor;  // 뱃지 배경색
  final Color barColor;    // 진행 바 색상
}

extension PlayerModelTier on PlayerModel {
  static const int _milestone = 300;

  /// 현재 티어 (300점 미만이면 null)
  TierInfo? get tier {
    if (accumulatedScore >= 1800) {
      return const TierInfo(
        name: 'MASTER',
        badgeColor: Color(0xFF6A0DAD),
        barColor: Color(0xFF9C27B0),
      );
    }
    if (accumulatedScore >= 1500) {
      return const TierInfo(
        name: 'DIAMOND',
        badgeColor: Color(0xFF1565C0),
        barColor: Color(0xFF42A5F5),
      );
    }
    if (accumulatedScore >= 1200) {
      return const TierInfo(
        name: 'PLATINUM',
        badgeColor: Color(0xFF00695C),
        barColor: Color(0xFF26A69A),
      );
    }
    if (accumulatedScore >= 900) {
      return const TierInfo(
        name: 'GOLD',
        badgeColor: Color(0xFFF57F17),
        barColor: Color(0xFFFFCA28),
      );
    }
    if (accumulatedScore >= 600) {
      return const TierInfo(
        name: 'SILVER',
        badgeColor: Color(0xFF757575),
        barColor: Color(0xFFBDBDBD),
      );
    }
    if (accumulatedScore >= 300) {
      return const TierInfo(
        name: 'BRONZE',
        badgeColor: Color(0xFF6D4C41),
        barColor: Color(0xFFBCAAA4),
      );
    }
    return null;
  }

  /// 다음 마일스톤 점수 (1800 이후로도 계속 300씩 증가)
  int get nextMilestone =>
      ((accumulatedScore ~/ _milestone) + 1) * _milestone;

  /// 현재 구간 내 진행도 (0.0 ~ 1.0) — 1800 이후로도 순환
  double get milestoneProgress =>
      (accumulatedScore % _milestone) / _milestone.toDouble();

  /// 현재 구간 시작 점수
  int get currentMilestone => (accumulatedScore ~/ _milestone) * _milestone;

  /// 진행 바 색상 — 구간마다 순환, 0~299 구간도 색상 있음
  Color get progressBarColor {
    const colors = [
      Color(0xFF66BB6A), // 0~299    초록
      Color(0xFFBCAAA4), // 300~599  브론즈
      Color(0xFFBDBDBD), // 600~899  실버
      Color(0xFFFFCA28), // 900~1199 골드
      Color(0xFF26A69A), // 1200~1499 플래티넘
      Color(0xFF42A5F5), // 1500~1799 다이아
      Color(0xFFAB47BC), // 1800~    마스터 (이후 순환)
    ];
    final idx = (accumulatedScore ~/ _milestone).clamp(0, colors.length - 1);
    return colors[idx];
  }
}

extension PlayerColumnExtension on PlayerColumn {
  String get label {
    switch (this) {
      case PlayerColumn.rank:
        return '순위';
      case PlayerColumn.name:
        return '이름';
      case PlayerColumn.winScore:
        return '승점';
      case PlayerColumn.accumulatedScore:
        return '24년이후\n누적 합계';
      case PlayerColumn.totalScore:
        return '총점';
      case PlayerColumn.attendanceScore:
        return '출석';
      case PlayerColumn.winRate:
        return '승률';
    }
  }
}

enum PlayerColumn {
  rank(65),
  name(150),
  totalScore(150),
  attendanceScore(150),
  winScore(150),
  winRate(110),
  accumulatedScore(230);

  const PlayerColumn(this.flex);
  final int flex;

  static List<PlayerColumn> get allColumns => values;

  static List<PlayerColumn> get currentYearColumns => values
      .where((column) =>
          column != PlayerColumn.winScore &&
          column != PlayerColumn.totalScore)
      .toList();
}
