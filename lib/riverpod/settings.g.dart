// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsDataImpl _$$SettingsDataImplFromJson(Map<String, dynamic> json) =>
    _$SettingsDataImpl(
      multipleAdbInstances:
          (json['multipleAdbInstances'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$$SettingsDataImplToJson(_$SettingsDataImpl instance) =>
    <String, dynamic>{
      'multipleAdbInstances': instance.multipleAdbInstances,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preferencesHash() => r'8db551367efd8284173ebfc9ff48f9a145f9bbb9';

/// See also [preferences].
@ProviderFor(preferences)
final preferencesProvider = Provider<SharedPreferences>.internal(
  preferences,
  name: r'preferencesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$preferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PreferencesRef = ProviderRef<SharedPreferences>;
String _$settingsHash() => r'18a5bb5302ad091b8a2c1c93abb1003123b92627';

/// See also [Settings].
@ProviderFor(Settings)
final settingsProvider = NotifierProvider<Settings, SettingsData>.internal(
  Settings.new,
  name: r'settingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Settings = Notifier<SettingsData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
