import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_model.freezed.dart';
part 'record_model.g.dart';

@freezed
@JsonSerializable()
class RecordModel with _$RecordModel {
  RecordModel({
    required this.date,
    required this.attendanceScore,
    required this.winScore,
    required this.winningGames,
    required this.totalGames,
  });

  @override
  final String date;
  @override
  final int attendanceScore;
  @override
  final int winScore;
  @override
  final double winningGames;
  @override
  final int totalGames;

  factory RecordModel.fromJson(Map<String, dynamic> json) => _$RecordModelFromJson(json);

  Map<String, Object?> toJson() => _$RecordModelToJson(this);
}

extension RecordModelPresentation on RecordModel {
  String valueByColumn(PlayerRecordColumn column) {
    switch (column) {
      case PlayerRecordColumn.date:
        return date;
      case PlayerRecordColumn.attendanceScore:
        return '$attendanceScore점';
      case PlayerRecordColumn.totalGames:
        return '$totalGames경기';
      case PlayerRecordColumn.winningGames:
        return '$winningGames경기';
      case PlayerRecordColumn.winScore:
        return '$winScore점';
    }
  }
}

extension PlayerRecordColumnExtension on PlayerRecordColumn {
  String get label {
    switch (this) {
      case PlayerRecordColumn.date: return '날짜';
      case PlayerRecordColumn.attendanceScore: return '출석';
      case PlayerRecordColumn.totalGames: return '경기 수';
      case PlayerRecordColumn.winningGames: return '승리';
      case PlayerRecordColumn.winScore: return '승점';
    }
  }
}


enum PlayerRecordColumn {
  date(200),
  attendanceScore(100),
  totalGames(130),
  winningGames(130),
  winScore(100);

  const PlayerRecordColumn(this.flex);
  final int flex;
}