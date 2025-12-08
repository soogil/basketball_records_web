// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordModel _$RecordModelFromJson(Map<String, dynamic> json) => RecordModel(
      date: json['date'] as String,
      attendanceScore: (json['attendanceScore'] as num).toInt(),
      winScore: (json['winScore'] as num).toInt(),
      winningGames: (json['winningGames'] as num).toDouble(),
      totalGames: (json['totalGames'] as num).toInt(),
    );

Map<String, dynamic> _$RecordModelToJson(RecordModel instance) =>
    <String, dynamic>{
      'date': instance.date,
      'attendanceScore': instance.attendanceScore,
      'winScore': instance.winScore,
      'winningGames': instance.winningGames,
      'totalGames': instance.totalGames,
    };
