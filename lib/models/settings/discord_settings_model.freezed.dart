// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discord_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiscordSettingsModel {
  bool get enabled;
  String get applicationId;
  List<String> get excludedLibraries;

  /// Create a copy of DiscordSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DiscordSettingsModelCopyWith<DiscordSettingsModel> get copyWith =>
      _$DiscordSettingsModelCopyWithImpl<DiscordSettingsModel>(
          this as DiscordSettingsModel, _$identity);

  /// Serializes this DiscordSettingsModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  String toString() {
    return 'DiscordSettingsModel(enabled: $enabled, applicationId: $applicationId, excludedLibraries: $excludedLibraries)';
  }
}

/// @nodoc
abstract mixin class $DiscordSettingsModelCopyWith<$Res> {
  factory $DiscordSettingsModelCopyWith(DiscordSettingsModel value,
          $Res Function(DiscordSettingsModel) _then) =
      _$DiscordSettingsModelCopyWithImpl;
  @useResult
  $Res call(
      {bool enabled, String applicationId, List<String> excludedLibraries});
}

/// @nodoc
class _$DiscordSettingsModelCopyWithImpl<$Res>
    implements $DiscordSettingsModelCopyWith<$Res> {
  _$DiscordSettingsModelCopyWithImpl(this._self, this._then);

  final DiscordSettingsModel _self;
  final $Res Function(DiscordSettingsModel) _then;

  /// Create a copy of DiscordSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? applicationId = null,
    Object? excludedLibraries = null,
  }) {
    return _then(_self.copyWith(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      applicationId: null == applicationId
          ? _self.applicationId
          : applicationId // ignore: cast_nullable_to_non_nullable
              as String,
      excludedLibraries: null == excludedLibraries
          ? _self.excludedLibraries
          : excludedLibraries // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DiscordSettingsModel].
extension DiscordSettingsModelPatterns on DiscordSettingsModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DiscordSettingsModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DiscordSettingsModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DiscordSettingsModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscordSettingsModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DiscordSettingsModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscordSettingsModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            bool enabled, String applicationId, List<String> excludedLibraries)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DiscordSettingsModel() when $default != null:
        return $default(
            _that.enabled, _that.applicationId, _that.excludedLibraries);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            bool enabled, String applicationId, List<String> excludedLibraries)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscordSettingsModel():
        return $default(
            _that.enabled, _that.applicationId, _that.excludedLibraries);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            bool enabled, String applicationId, List<String> excludedLibraries)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DiscordSettingsModel() when $default != null:
        return $default(
            _that.enabled, _that.applicationId, _that.excludedLibraries);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DiscordSettingsModel extends DiscordSettingsModel {
  const _DiscordSettingsModel(
      {this.enabled = false,
      this.applicationId = '1449114323279548416',
      final List<String> excludedLibraries = const []})
      : _excludedLibraries = excludedLibraries,
        super._();
  factory _DiscordSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$DiscordSettingsModelFromJson(json);

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final String applicationId;
  final List<String> _excludedLibraries;
  @override
  @JsonKey()
  List<String> get excludedLibraries {
    if (_excludedLibraries is EqualUnmodifiableListView)
      return _excludedLibraries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_excludedLibraries);
  }

  /// Create a copy of DiscordSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DiscordSettingsModelCopyWith<_DiscordSettingsModel> get copyWith =>
      __$DiscordSettingsModelCopyWithImpl<_DiscordSettingsModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DiscordSettingsModelToJson(
      this,
    );
  }

  @override
  String toString() {
    return 'DiscordSettingsModel(enabled: $enabled, applicationId: $applicationId, excludedLibraries: $excludedLibraries)';
  }
}

/// @nodoc
abstract mixin class _$DiscordSettingsModelCopyWith<$Res>
    implements $DiscordSettingsModelCopyWith<$Res> {
  factory _$DiscordSettingsModelCopyWith(_DiscordSettingsModel value,
          $Res Function(_DiscordSettingsModel) _then) =
      __$DiscordSettingsModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool enabled, String applicationId, List<String> excludedLibraries});
}

/// @nodoc
class __$DiscordSettingsModelCopyWithImpl<$Res>
    implements _$DiscordSettingsModelCopyWith<$Res> {
  __$DiscordSettingsModelCopyWithImpl(this._self, this._then);

  final _DiscordSettingsModel _self;
  final $Res Function(_DiscordSettingsModel) _then;

  /// Create a copy of DiscordSettingsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? enabled = null,
    Object? applicationId = null,
    Object? excludedLibraries = null,
  }) {
    return _then(_DiscordSettingsModel(
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      applicationId: null == applicationId
          ? _self.applicationId
          : applicationId // ignore: cast_nullable_to_non_nullable
              as String,
      excludedLibraries: null == excludedLibraries
          ? _self._excludedLibraries
          : excludedLibraries // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
