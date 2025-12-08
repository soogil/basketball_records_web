// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_detail_record_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playerDetailRecordViewModelHash() =>
    r'30a4f1fe13ae7602e8cfd52ecd28a73aea221fe9';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$PlayerDetailRecordViewModel
    extends BuildlessAutoDisposeAsyncNotifier<DateRecords> {
  late final String playerId;

  FutureOr<DateRecords> build(
    String playerId,
  );
}

/// See also [PlayerDetailRecordViewModel].
@ProviderFor(PlayerDetailRecordViewModel)
const playerDetailRecordViewModelProvider = PlayerDetailRecordViewModelFamily();

/// See also [PlayerDetailRecordViewModel].
class PlayerDetailRecordViewModelFamily
    extends Family<AsyncValue<DateRecords>> {
  /// See also [PlayerDetailRecordViewModel].
  const PlayerDetailRecordViewModelFamily();

  /// See also [PlayerDetailRecordViewModel].
  PlayerDetailRecordViewModelProvider call(
    String playerId,
  ) {
    return PlayerDetailRecordViewModelProvider(
      playerId,
    );
  }

  @override
  PlayerDetailRecordViewModelProvider getProviderOverride(
    covariant PlayerDetailRecordViewModelProvider provider,
  ) {
    return call(
      provider.playerId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'playerDetailRecordViewModelProvider';
}

/// See also [PlayerDetailRecordViewModel].
class PlayerDetailRecordViewModelProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PlayerDetailRecordViewModel,
        DateRecords> {
  /// See also [PlayerDetailRecordViewModel].
  PlayerDetailRecordViewModelProvider(
    String playerId,
  ) : this._internal(
          () => PlayerDetailRecordViewModel()..playerId = playerId,
          from: playerDetailRecordViewModelProvider,
          name: r'playerDetailRecordViewModelProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$playerDetailRecordViewModelHash,
          dependencies: PlayerDetailRecordViewModelFamily._dependencies,
          allTransitiveDependencies:
              PlayerDetailRecordViewModelFamily._allTransitiveDependencies,
          playerId: playerId,
        );

  PlayerDetailRecordViewModelProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.playerId,
  }) : super.internal();

  final String playerId;

  @override
  FutureOr<DateRecords> runNotifierBuild(
    covariant PlayerDetailRecordViewModel notifier,
  ) {
    return notifier.build(
      playerId,
    );
  }

  @override
  Override overrideWith(PlayerDetailRecordViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: PlayerDetailRecordViewModelProvider._internal(
        () => create()..playerId = playerId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        playerId: playerId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PlayerDetailRecordViewModel,
      DateRecords> createElement() {
    return _PlayerDetailRecordViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerDetailRecordViewModelProvider &&
        other.playerId == playerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, playerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PlayerDetailRecordViewModelRef
    on AutoDisposeAsyncNotifierProviderRef<DateRecords> {
  /// The parameter `playerId` of this provider.
  String get playerId;
}

class _PlayerDetailRecordViewModelProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PlayerDetailRecordViewModel,
        DateRecords> with PlayerDetailRecordViewModelRef {
  _PlayerDetailRecordViewModelProviderElement(super.provider);

  @override
  String get playerId =>
      (origin as PlayerDetailRecordViewModelProvider).playerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
