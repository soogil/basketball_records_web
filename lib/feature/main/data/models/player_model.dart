import 'package:flutter/cupertino.dart';
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

  factory PlayerModel.fromJson(Map<String, dynamic> json) => _$PlayerModelFromJson(json);

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
      );
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
    if (accumulatedScore > 1800) {
      return Color(0xFF5C2FC2);
    } else if (accumulatedScore > 1500) {
      return Color(0xFFB33791);
    } else if (accumulatedScore > 1200) {
      return Color(0xFF362FD9);
    } else if (accumulatedScore > 900) {
      return Color(0xFF40A578);
    } else if (accumulatedScore > 600) {
      return Color(0xFFFF7601);
    } else if (accumulatedScore > 300) {
      return Color(0xFFE52020);
    }

    return BRColors.black;
  }

  double get winRate =>
      seasonTotalGames == 0
          ? 0
          : (seasonTotalWins/seasonTotalGames) * 100;
}

extension PlayerColumnExtension on PlayerColumn {
  String get label {
    switch (this) {
      case PlayerColumn.rank: return '순위';
      case PlayerColumn.name: return '이름';
      case PlayerColumn.winScore: return '승점';
      case PlayerColumn.accumulatedScore: return '24년~25년\n누적 합계';
      case PlayerColumn.totalScore: return '총점';
      case PlayerColumn.attendanceScore: return '출석';
      case PlayerColumn.winRate: return '승률';
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
}