// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecordModel {
  String get date;
  int get attendanceScore;
  int get winScore;
  double get winningGames;
  int get totalGames;

  /// Create a copy of RecordModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecordModelCopyWith<RecordModel> get copyWith =>
      _$RecordModelCopyWithImpl<RecordModel>(this as RecordModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecordModel &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.attendanceScore, attendanceScore) ||
                other.attendanceScore == attendanceScore) &&
            (identical(other.winScore, winScore) ||
                other.winScore == winScore) &&
            (identical(other.winningGames, winningGames) ||
                other.winningGames == winningGames) &&
            (identical(other.totalGames, totalGames) ||
                other.totalGames == totalGames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, date, attendanceScore, winScore, winningGames, totalGames);

  @override
  String toString() {
    return 'RecordModel(date: $date, attendanceScore: $attendanceScore, winScore: $winScore, winningGames: $winningGames, totalGames: $totalGames)';
  }
}

/// @nodoc
abstract mixin class $RecordModelCopyWith<$Res> {
  factory $RecordModelCopyWith(
          RecordModel value, $Res Function(RecordModel) _then) =
      _$RecordModelCopyWithImpl;
  @useResult
  $Res call(
      {String date,
      int attendanceScore,
      int winScore,
      double winningGames,
      int totalGames});
}

/// @nodoc
class _$RecordModelCopyWithImpl<$Res> implements $RecordModelCopyWith<$Res> {
  _$RecordModelCopyWithImpl(this._self, this._then);

  final RecordModel _self;
  final $Res Function(RecordModel) _then;

  /// Create a copy of RecordModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? attendanceScore = null,
    Object? winScore = null,
    Object? winningGames = null,
    Object? totalGames = null,
  }) {
    return _then(RecordModel(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      attendanceScore: null == attendanceScore
          ? _self.attendanceScore
          : attendanceScore // ignore: cast_nullable_to_non_nullable
              as int,
      winScore: null == winScore
          ? _self.winScore
          : winScore // ignore: cast_nullable_to_non_nullable
              as int,
      winningGames: null == winningGames
          ? _self.winningGames
          : winningGames // ignore: cast_nullable_to_non_nullable
              as double,
      totalGames: null == totalGames
          ? _self.totalGames
          : totalGames // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
