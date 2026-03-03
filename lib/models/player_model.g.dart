// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlayerModel _$PlayerModelFromJson(Map<String, dynamic> json) => PlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      totalScore: (json['totalScore'] as num).toInt(),
      attendanceScore: (json['attendanceScore'] as num).toInt(),
      accumulatedScore: (json['accumulatedScore'] as num).toInt(),
      winScore: (json['winScore'] as num).toInt(),
      seasonTotalGames: (json['seasonTotalGames'] as num).toInt(),
      seasonTotalWins: (json['seasonTotalWins'] as num).toDouble(),
      scoreAchieved: json['scoreAchieved'] as bool,
    );

Map<String, dynamic> _$PlayerModelToJson(PlayerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'totalScore': instance.totalScore,
      'attendanceScore': instance.attendanceScore,
      'winScore': instance.winScore,
      'seasonTotalWins': instance.seasonTotalWins,
      'seasonTotalGames': instance.seasonTotalGames,
      'accumulatedScore': instance.accumulatedScore,
      'scoreAchieved': instance.scoreAchieved,
    };
