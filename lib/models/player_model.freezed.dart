// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerModel {
  String get id;
  String get name;
  int get totalScore;
  int get attendanceScore;
  int get winScore;
  double get seasonTotalWins;
  int get seasonTotalGames;
  int get accumulatedScore;
  bool get scoreAchieved;

  /// Create a copy of PlayerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayerModelCopyWith<PlayerModel> get copyWith =>
      _$PlayerModelCopyWithImpl<PlayerModel>(this as PlayerModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayerModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.totalScore, totalScore) ||
                other.totalScore == totalScore) &&
            (identical(other.attendanceScore, attendanceScore) ||
                other.attendanceScore == attendanceScore) &&
            (identical(other.winScore, winScore) ||
                other.winScore == winScore) &&
            (identical(other.seasonTotalWins, seasonTotalWins) ||
                other.seasonTotalWins == seasonTotalWins) &&
            (identical(other.seasonTotalGames, seasonTotalGames) ||
                other.seasonTotalGames == seasonTotalGames) &&
            (identical(other.accumulatedScore, accumulatedScore) ||
                other.accumulatedScore == accumulatedScore) &&
            (identical(other.scoreAchieved, scoreAchieved) ||
                other.scoreAchieved == scoreAchieved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      totalScore,
      attendanceScore,
      winScore,
      seasonTotalWins,
      seasonTotalGames,
      accumulatedScore,
      scoreAchieved);

  @override
  String toString() {
    return 'PlayerModel(id: $id, name: $name, totalScore: $totalScore, attendanceScore: $attendanceScore, winScore: $winScore, seasonTotalWins: $seasonTotalWins, seasonTotalGames: $seasonTotalGames, accumulatedScore: $accumulatedScore, scoreAchieved: $scoreAchieved)';
  }
}

/// @nodoc
abstract mixin class $PlayerModelCopyWith<$Res> {
  factory $PlayerModelCopyWith(
          PlayerModel value, $Res Function(PlayerModel) _then) =
      _$PlayerModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      int totalScore,
      int attendanceScore,
      int accumulatedScore,
      int winScore,
      int seasonTotalGames,
      double seasonTotalWins,
      bool scoreAchieved});
}

/// @nodoc
class _$PlayerModelCopyWithImpl<$Res> implements $PlayerModelCopyWith<$Res> {
  _$PlayerModelCopyWithImpl(this._self, this._then);

  final PlayerModel _self;
  final $Res Function(PlayerModel) _then;

  /// Create a copy of PlayerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? totalScore = null,
    Object? attendanceScore = null,
    Object? accumulatedScore = null,
    Object? winScore = null,
    Object? seasonTotalGames = null,
    Object? seasonTotalWins = null,
    Object? scoreAchieved = null,
  }) {
    return _then(PlayerModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      totalScore: null == totalScore
          ? _self.totalScore
          : totalScore // ignore: cast_nullable_to_non_nullable
              as int,
      attendanceScore: null == attendanceScore
          ? _self.attendanceScore
          : attendanceScore // ignore: cast_nullable_to_non_nullable
              as int,
      accumulatedScore: null == accumulatedScore
          ? _self.accumulatedScore
          : accumulatedScore // ignore: cast_nullable_to_non_nullable
              as int,
      winScore: null == winScore
          ? _self.winScore
          : winScore // ignore: cast_nullable_to_non_nullable
              as int,
      seasonTotalGames: null == seasonTotalGames
          ? _self.seasonTotalGames
          : seasonTotalGames // ignore: cast_nullable_to_non_nullable
              as int,
      seasonTotalWins: null == seasonTotalWins
          ? _self.seasonTotalWins
          : seasonTotalWins // ignore: cast_nullable_to_non_nullable
              as double,
      scoreAchieved: null == scoreAchieved
          ? _self.scoreAchieved
          : scoreAchieved // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
