// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_detail_presenter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$playerDetailPresenterHash() =>
    r'c1799e4e56f7fae346d055091fe7415099f71ea1';

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

abstract class _$PlayerDetailPresenter
    extends BuildlessAutoDisposeAsyncNotifier<PlayerDetailState> {
  late final String playerId;

  FutureOr<PlayerDetailState> build(
    String playerId,
  );
}

/// See also [PlayerDetailPresenter].
@ProviderFor(PlayerDetailPresenter)
const playerDetailPresenterProvider = PlayerDetailPresenterFamily();

/// See also [PlayerDetailPresenter].
class PlayerDetailPresenterFamily
    extends Family<AsyncValue<PlayerDetailState>> {
  /// See also [PlayerDetailPresenter].
  const PlayerDetailPresenterFamily();

  /// See also [PlayerDetailPresenter].
  PlayerDetailPresenterProvider call(
    String playerId,
  ) {
    return PlayerDetailPresenterProvider(
      playerId,
    );
  }

  @override
  PlayerDetailPresenterProvider getProviderOverride(
    covariant PlayerDetailPresenterProvider provider,
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
  String? get name => r'playerDetailPresenterProvider';
}

/// See also [PlayerDetailPresenter].
class PlayerDetailPresenterProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PlayerDetailPresenter,
        PlayerDetailState> {
  /// See also [PlayerDetailPresenter].
  PlayerDetailPresenterProvider(
    String playerId,
  ) : this._internal(
          () => PlayerDetailPresenter()..playerId = playerId,
          from: playerDetailPresenterProvider,
          name: r'playerDetailPresenterProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$playerDetailPresenterHash,
          dependencies: PlayerDetailPresenterFamily._dependencies,
          allTransitiveDependencies:
              PlayerDetailPresenterFamily._allTransitiveDependencies,
          playerId: playerId,
        );

  PlayerDetailPresenterProvider._internal(
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
  FutureOr<PlayerDetailState> runNotifierBuild(
    covariant PlayerDetailPresenter notifier,
  ) {
    return notifier.build(
      playerId,
    );
  }

  @override
  Override overrideWith(PlayerDetailPresenter Function() create) {
    return ProviderOverride(
      origin: this,
      override: PlayerDetailPresenterProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<PlayerDetailPresenter,
      PlayerDetailState> createElement() {
    return _PlayerDetailPresenterProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerDetailPresenterProvider && other.playerId == playerId;
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
mixin PlayerDetailPresenterRef
    on AutoDisposeAsyncNotifierProviderRef<PlayerDetailState> {
  /// The parameter `playerId` of this provider.
  String get playerId;
}

class _PlayerDetailPresenterProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PlayerDetailPresenter,
        PlayerDetailState> with PlayerDetailPresenterRef {
  _PlayerDetailPresenterProviderElement(super.provider);

  @override
  String get playerId => (origin as PlayerDetailPresenterProvider).playerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
