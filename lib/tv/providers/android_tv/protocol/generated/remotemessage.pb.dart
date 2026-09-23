// This is a generated file - do not edit.
//
// Generated from remotemessage.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'remotemessage.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'remotemessage.pbenum.dart';

class RemoteAppLinkLaunchRequest extends $pb.GeneratedMessage {
  factory RemoteAppLinkLaunchRequest({
    $core.String? appLink,
  }) {
    final result = RemoteAppLinkLaunchRequest._();
    if (appLink != null) result.appLink = appLink;
    return result;
  }

  RemoteAppLinkLaunchRequest._();

  factory RemoteAppLinkLaunchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteAppLinkLaunchRequest()..mergeFromBuffer(data, registry);
  factory RemoteAppLinkLaunchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteAppLinkLaunchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteAppLinkLaunchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteAppLinkLaunchRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'appLink')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteAppLinkLaunchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteAppLinkLaunchRequest copyWith(
          void Function(RemoteAppLinkLaunchRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RemoteAppLinkLaunchRequest))
          as RemoteAppLinkLaunchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteAppLinkLaunchRequest() / RemoteAppLinkLaunchRequest.new instead')
  static RemoteAppLinkLaunchRequest create() => RemoteAppLinkLaunchRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      RemoteAppLinkLaunchRequest._();
  @$core.override
  RemoteAppLinkLaunchRequest createEmptyInstance() =>
      RemoteAppLinkLaunchRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoteAppLinkLaunchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteAppLinkLaunchRequest>(
          RemoteAppLinkLaunchRequest.$_createMessage);
  static RemoteAppLinkLaunchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get appLink => $_getSZ(0);
  @$pb.TagNumber(1)
  set appLink($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAppLink() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppLink() => $_clearField(1);
}

class RemoteResetPreferredAudioDevice extends $pb.GeneratedMessage {
  factory RemoteResetPreferredAudioDevice() =>
      RemoteResetPreferredAudioDevice._();

  RemoteResetPreferredAudioDevice._();

  factory RemoteResetPreferredAudioDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteResetPreferredAudioDevice()..mergeFromBuffer(data, registry);
  factory RemoteResetPreferredAudioDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteResetPreferredAudioDevice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteResetPreferredAudioDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteResetPreferredAudioDevice.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteResetPreferredAudioDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteResetPreferredAudioDevice copyWith(
          void Function(RemoteResetPreferredAudioDevice) updates) =>
      super.copyWith(
              (message) => updates(message as RemoteResetPreferredAudioDevice))
          as RemoteResetPreferredAudioDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteResetPreferredAudioDevice() / RemoteResetPreferredAudioDevice.new instead')
  static RemoteResetPreferredAudioDevice create() =>
      RemoteResetPreferredAudioDevice._();
  static $pb.GeneratedMessage $_createMessage() =>
      RemoteResetPreferredAudioDevice._();
  @$core.override
  RemoteResetPreferredAudioDevice createEmptyInstance() =>
      RemoteResetPreferredAudioDevice._();
  @$core.pragma('dart2js:noInline')
  static RemoteResetPreferredAudioDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteResetPreferredAudioDevice>(
          RemoteResetPreferredAudioDevice.$_createMessage);
  static RemoteResetPreferredAudioDevice? _defaultInstance;
}

class RemoteSetPreferredAudioDevice extends $pb.GeneratedMessage {
  factory RemoteSetPreferredAudioDevice() => RemoteSetPreferredAudioDevice._();

  RemoteSetPreferredAudioDevice._();

  factory RemoteSetPreferredAudioDevice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSetPreferredAudioDevice()..mergeFromBuffer(data, registry);
  factory RemoteSetPreferredAudioDevice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSetPreferredAudioDevice()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteSetPreferredAudioDevice',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteSetPreferredAudioDevice.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSetPreferredAudioDevice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSetPreferredAudioDevice copyWith(
          void Function(RemoteSetPreferredAudioDevice) updates) =>
      super.copyWith(
              (message) => updates(message as RemoteSetPreferredAudioDevice))
          as RemoteSetPreferredAudioDevice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteSetPreferredAudioDevice() / RemoteSetPreferredAudioDevice.new instead')
  static RemoteSetPreferredAudioDevice create() =>
      RemoteSetPreferredAudioDevice._();
  static $pb.GeneratedMessage $_createMessage() =>
      RemoteSetPreferredAudioDevice._();
  @$core.override
  RemoteSetPreferredAudioDevice createEmptyInstance() =>
      RemoteSetPreferredAudioDevice._();
  @$core.pragma('dart2js:noInline')
  static RemoteSetPreferredAudioDevice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteSetPreferredAudioDevice>(
          RemoteSetPreferredAudioDevice.$_createMessage);
  static RemoteSetPreferredAudioDevice? _defaultInstance;
}

class RemoteAdjustVolumeLevel extends $pb.GeneratedMessage {
  factory RemoteAdjustVolumeLevel() => RemoteAdjustVolumeLevel._();

  RemoteAdjustVolumeLevel._();

  factory RemoteAdjustVolumeLevel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteAdjustVolumeLevel()..mergeFromBuffer(data, registry);
  factory RemoteAdjustVolumeLevel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteAdjustVolumeLevel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteAdjustVolumeLevel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteAdjustVolumeLevel.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteAdjustVolumeLevel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteAdjustVolumeLevel copyWith(
          void Function(RemoteAdjustVolumeLevel) updates) =>
      super.copyWith((message) => updates(message as RemoteAdjustVolumeLevel))
          as RemoteAdjustVolumeLevel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteAdjustVolumeLevel() / RemoteAdjustVolumeLevel.new instead')
  static RemoteAdjustVolumeLevel create() => RemoteAdjustVolumeLevel._();
  static $pb.GeneratedMessage $_createMessage() => RemoteAdjustVolumeLevel._();
  @$core.override
  RemoteAdjustVolumeLevel createEmptyInstance() => RemoteAdjustVolumeLevel._();
  @$core.pragma('dart2js:noInline')
  static RemoteAdjustVolumeLevel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteAdjustVolumeLevel>(
          RemoteAdjustVolumeLevel.$_createMessage);
  static RemoteAdjustVolumeLevel? _defaultInstance;
}

class RemoteSetVolumeLevel extends $pb.GeneratedMessage {
  factory RemoteSetVolumeLevel({
    $core.int? unknown1,
    $core.int? unknown2,
    $core.String? playerModel,
    $core.int? unknown4,
    $core.int? unknown5,
    $core.int? volumeMax,
    $core.int? volumeLevel,
    $core.bool? volumeMuted,
  }) {
    final result = RemoteSetVolumeLevel._();
    if (unknown1 != null) result.unknown1 = unknown1;
    if (unknown2 != null) result.unknown2 = unknown2;
    if (playerModel != null) result.playerModel = playerModel;
    if (unknown4 != null) result.unknown4 = unknown4;
    if (unknown5 != null) result.unknown5 = unknown5;
    if (volumeMax != null) result.volumeMax = volumeMax;
    if (volumeLevel != null) result.volumeLevel = volumeLevel;
    if (volumeMuted != null) result.volumeMuted = volumeMuted;
    return result;
  }

  RemoteSetVolumeLevel._();

  factory RemoteSetVolumeLevel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSetVolumeLevel()..mergeFromBuffer(data, registry);
  factory RemoteSetVolumeLevel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSetVolumeLevel()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteSetVolumeLevel',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteSetVolumeLevel.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'unknown1', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'unknown2', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'playerModel')
    ..aI(4, _omitFieldNames ? '' : 'unknown4', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'unknown5', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'volumeMax', fieldType: $pb.PbFieldType.OU3)
    ..aI(7, _omitFieldNames ? '' : 'volumeLevel',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(8, _omitFieldNames ? '' : 'volumeMuted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSetVolumeLevel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSetVolumeLevel copyWith(void Function(RemoteSetVolumeLevel) updates) =>
      super.copyWith((message) => updates(message as RemoteSetVolumeLevel))
          as RemoteSetVolumeLevel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteSetVolumeLevel() / RemoteSetVolumeLevel.new instead')
  static RemoteSetVolumeLevel create() => RemoteSetVolumeLevel._();
  static $pb.GeneratedMessage $_createMessage() => RemoteSetVolumeLevel._();
  @$core.override
  RemoteSetVolumeLevel createEmptyInstance() => RemoteSetVolumeLevel._();
  @$core.pragma('dart2js:noInline')
  static RemoteSetVolumeLevel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteSetVolumeLevel>(
          RemoteSetVolumeLevel.$_createMessage);
  static RemoteSetVolumeLevel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get unknown1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set unknown1($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnknown1() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnknown1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get unknown2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set unknown2($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUnknown2() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnknown2() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get playerModel => $_getSZ(2);
  @$pb.TagNumber(3)
  set playerModel($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlayerModel() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlayerModel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get unknown4 => $_getIZ(3);
  @$pb.TagNumber(4)
  set unknown4($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUnknown4() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnknown4() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get unknown5 => $_getIZ(4);
  @$pb.TagNumber(5)
  set unknown5($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUnknown5() => $_has(4);
  @$pb.TagNumber(5)
  void clearUnknown5() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get volumeMax => $_getIZ(5);
  @$pb.TagNumber(6)
  set volumeMax($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasVolumeMax() => $_has(5);
  @$pb.TagNumber(6)
  void clearVolumeMax() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get volumeLevel => $_getIZ(6);
  @$pb.TagNumber(7)
  set volumeLevel($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasVolumeLevel() => $_has(6);
  @$pb.TagNumber(7)
  void clearVolumeLevel() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get volumeMuted => $_getBF(7);
  @$pb.TagNumber(8)
  set volumeMuted($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVolumeMuted() => $_has(7);
  @$pb.TagNumber(8)
  void clearVolumeMuted() => $_clearField(8);
}

class RemoteStart extends $pb.GeneratedMessage {
  factory RemoteStart({
    $core.bool? started,
  }) {
    final result = RemoteStart._();
    if (started != null) result.started = started;
    return result;
  }

  RemoteStart._();

  factory RemoteStart.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteStart()..mergeFromBuffer(data, registry);
  factory RemoteStart.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteStart()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteStart',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteStart.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'started')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteStart clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteStart copyWith(void Function(RemoteStart) updates) =>
      super.copyWith((message) => updates(message as RemoteStart))
          as RemoteStart;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteStart() / RemoteStart.new instead')
  static RemoteStart create() => RemoteStart._();
  static $pb.GeneratedMessage $_createMessage() => RemoteStart._();
  @$core.override
  RemoteStart createEmptyInstance() => RemoteStart._();
  @$core.pragma('dart2js:noInline')
  static RemoteStart getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteStart>(
          RemoteStart.$_createMessage);
  static RemoteStart? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get started => $_getBF(0);
  @$pb.TagNumber(1)
  set started($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStarted() => $_has(0);
  @$pb.TagNumber(1)
  void clearStarted() => $_clearField(1);
}

class RemoteVoiceEnd extends $pb.GeneratedMessage {
  factory RemoteVoiceEnd({
    $core.int? sessionId,
  }) {
    final result = RemoteVoiceEnd._();
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  RemoteVoiceEnd._();

  factory RemoteVoiceEnd.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteVoiceEnd()..mergeFromBuffer(data, registry);
  factory RemoteVoiceEnd.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteVoiceEnd()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteVoiceEnd',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteVoiceEnd.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteVoiceEnd clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteVoiceEnd copyWith(void Function(RemoteVoiceEnd) updates) =>
      super.copyWith((message) => updates(message as RemoteVoiceEnd))
          as RemoteVoiceEnd;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteVoiceEnd() / RemoteVoiceEnd.new instead')
  static RemoteVoiceEnd create() => RemoteVoiceEnd._();
  static $pb.GeneratedMessage $_createMessage() => RemoteVoiceEnd._();
  @$core.override
  RemoteVoiceEnd createEmptyInstance() => RemoteVoiceEnd._();
  @$core.pragma('dart2js:noInline')
  static RemoteVoiceEnd getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteVoiceEnd>(
          RemoteVoiceEnd.$_createMessage);
  static RemoteVoiceEnd? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get sessionId => $_getIZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);
}

class RemoteVoicePayload extends $pb.GeneratedMessage {
  factory RemoteVoicePayload({
    $core.int? sessionId,
    $core.List<$core.int>? samples,
  }) {
    final result = RemoteVoicePayload._();
    if (sessionId != null) result.sessionId = sessionId;
    if (samples != null) result.samples = samples;
    return result;
  }

  RemoteVoicePayload._();

  factory RemoteVoicePayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteVoicePayload()..mergeFromBuffer(data, registry);
  factory RemoteVoicePayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteVoicePayload()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteVoicePayload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteVoicePayload.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'sessionId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'samples', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteVoicePayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteVoicePayload copyWith(void Function(RemoteVoicePayload) updates) =>
      super.copyWith((message) => updates(message as RemoteVoicePayload))
          as RemoteVoicePayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteVoicePayload() / RemoteVoicePayload.new instead')
  static RemoteVoicePayload create() => RemoteVoicePayload._();
  static $pb.GeneratedMessage $_createMessage() => RemoteVoicePayload._();
  @$core.override
  RemoteVoicePayload createEmptyInstance() => RemoteVoicePayload._();
  @$core.pragma('dart2js:noInline')
  static RemoteVoicePayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteVoicePayload>(
          RemoteVoicePayload.$_createMessage);
  static RemoteVoicePayload? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get sessionId => $_getIZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get samples => $_getN(1);
  @$pb.TagNumber(2)
  set samples($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSamples() => $_has(1);
  @$pb.TagNumber(2)
  void clearSamples() => $_clearField(2);
}

class RemoteVoiceBegin extends $pb.GeneratedMessage {
  factory RemoteVoiceBegin({
    $core.int? sessionId,
    $core.String? packageName,
  }) {
    final result = RemoteVoiceBegin._();
    if (sessionId != null) result.sessionId = sessionId;
    if (packageName != null) result.packageName = packageName;
    return result;
  }

  RemoteVoiceBegin._();

  factory RemoteVoiceBegin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteVoiceBegin()..mergeFromBuffer(data, registry);
  factory RemoteVoiceBegin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteVoiceBegin()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteVoiceBegin',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteVoiceBegin.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'sessionId')
    ..aOS(2, _omitFieldNames ? '' : 'packageName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteVoiceBegin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteVoiceBegin copyWith(void Function(RemoteVoiceBegin) updates) =>
      super.copyWith((message) => updates(message as RemoteVoiceBegin))
          as RemoteVoiceBegin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteVoiceBegin() / RemoteVoiceBegin.new instead')
  static RemoteVoiceBegin create() => RemoteVoiceBegin._();
  static $pb.GeneratedMessage $_createMessage() => RemoteVoiceBegin._();
  @$core.override
  RemoteVoiceBegin createEmptyInstance() => RemoteVoiceBegin._();
  @$core.pragma('dart2js:noInline')
  static RemoteVoiceBegin getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteVoiceBegin>(
          RemoteVoiceBegin.$_createMessage);
  static RemoteVoiceBegin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get sessionId => $_getIZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get packageName => $_getSZ(1);
  @$pb.TagNumber(2)
  set packageName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPackageName() => $_has(1);
  @$pb.TagNumber(2)
  void clearPackageName() => $_clearField(2);
}

class RemoteTextFieldStatus extends $pb.GeneratedMessage {
  factory RemoteTextFieldStatus({
    $core.int? counterField,
    $core.String? value,
    $core.int? start,
    $core.int? end,
    $core.int? int5,
    $core.String? label,
  }) {
    final result = RemoteTextFieldStatus._();
    if (counterField != null) result.counterField = counterField;
    if (value != null) result.value = value;
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    if (int5 != null) result.int5 = int5;
    if (label != null) result.label = label;
    return result;
  }

  RemoteTextFieldStatus._();

  factory RemoteTextFieldStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteTextFieldStatus()..mergeFromBuffer(data, registry);
  factory RemoteTextFieldStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteTextFieldStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteTextFieldStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteTextFieldStatus.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'counterField')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aI(3, _omitFieldNames ? '' : 'start')
    ..aI(4, _omitFieldNames ? '' : 'end')
    ..aI(5, _omitFieldNames ? '' : 'int5')
    ..aOS(6, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteTextFieldStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteTextFieldStatus copyWith(
          void Function(RemoteTextFieldStatus) updates) =>
      super.copyWith((message) => updates(message as RemoteTextFieldStatus))
          as RemoteTextFieldStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteTextFieldStatus() / RemoteTextFieldStatus.new instead')
  static RemoteTextFieldStatus create() => RemoteTextFieldStatus._();
  static $pb.GeneratedMessage $_createMessage() => RemoteTextFieldStatus._();
  @$core.override
  RemoteTextFieldStatus createEmptyInstance() => RemoteTextFieldStatus._();
  @$core.pragma('dart2js:noInline')
  static RemoteTextFieldStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteTextFieldStatus>(
          RemoteTextFieldStatus.$_createMessage);
  static RemoteTextFieldStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get counterField => $_getIZ(0);
  @$pb.TagNumber(1)
  set counterField($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCounterField() => $_has(0);
  @$pb.TagNumber(1)
  void clearCounterField() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get start => $_getIZ(2);
  @$pb.TagNumber(3)
  set start($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStart() => $_has(2);
  @$pb.TagNumber(3)
  void clearStart() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get end => $_getIZ(3);
  @$pb.TagNumber(4)
  set end($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnd() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get int5 => $_getIZ(4);
  @$pb.TagNumber(5)
  set int5($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasInt5() => $_has(4);
  @$pb.TagNumber(5)
  void clearInt5() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get label => $_getSZ(5);
  @$pb.TagNumber(6)
  set label($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLabel() => $_has(5);
  @$pb.TagNumber(6)
  void clearLabel() => $_clearField(6);
}

class RemoteImeShowRequest extends $pb.GeneratedMessage {
  factory RemoteImeShowRequest({
    RemoteTextFieldStatus? remoteTextFieldStatus,
  }) {
    final result = RemoteImeShowRequest._();
    if (remoteTextFieldStatus != null)
      result.remoteTextFieldStatus = remoteTextFieldStatus;
    return result;
  }

  RemoteImeShowRequest._();

  factory RemoteImeShowRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeShowRequest()..mergeFromBuffer(data, registry);
  factory RemoteImeShowRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeShowRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteImeShowRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteImeShowRequest.$_createMessage)
    ..aOM<RemoteTextFieldStatus>(
        2, _omitFieldNames ? '' : 'remoteTextFieldStatus',
        subBuilder: RemoteTextFieldStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeShowRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeShowRequest copyWith(void Function(RemoteImeShowRequest) updates) =>
      super.copyWith((message) => updates(message as RemoteImeShowRequest))
          as RemoteImeShowRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RemoteImeShowRequest() / RemoteImeShowRequest.new instead')
  static RemoteImeShowRequest create() => RemoteImeShowRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemoteImeShowRequest._();
  @$core.override
  RemoteImeShowRequest createEmptyInstance() => RemoteImeShowRequest._();
  @$core.pragma('dart2js:noInline')
  static RemoteImeShowRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteImeShowRequest>(
          RemoteImeShowRequest.$_createMessage);
  static RemoteImeShowRequest? _defaultInstance;

  @$pb.TagNumber(2)
  RemoteTextFieldStatus get remoteTextFieldStatus => $_getN(0);
  @$pb.TagNumber(2)
  set remoteTextFieldStatus(RemoteTextFieldStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRemoteTextFieldStatus() => $_has(0);
  @$pb.TagNumber(2)
  void clearRemoteTextFieldStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  RemoteTextFieldStatus ensureRemoteTextFieldStatus() => $_ensure(0);
}

class RemoteEditInfo extends $pb.GeneratedMessage {
  factory RemoteEditInfo({
    $core.int? insert,
    RemoteImeObject? textFieldStatus,
  }) {
    final result = RemoteEditInfo._();
    if (insert != null) result.insert = insert;
    if (textFieldStatus != null) result.textFieldStatus = textFieldStatus;
    return result;
  }

  RemoteEditInfo._();

  factory RemoteEditInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteEditInfo()..mergeFromBuffer(data, registry);
  factory RemoteEditInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteEditInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteEditInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteEditInfo.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'insert')
    ..aOM<RemoteImeObject>(2, _omitFieldNames ? '' : 'textFieldStatus',
        subBuilder: RemoteImeObject.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteEditInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteEditInfo copyWith(void Function(RemoteEditInfo) updates) =>
      super.copyWith((message) => updates(message as RemoteEditInfo))
          as RemoteEditInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteEditInfo() / RemoteEditInfo.new instead')
  static RemoteEditInfo create() => RemoteEditInfo._();
  static $pb.GeneratedMessage $_createMessage() => RemoteEditInfo._();
  @$core.override
  RemoteEditInfo createEmptyInstance() => RemoteEditInfo._();
  @$core.pragma('dart2js:noInline')
  static RemoteEditInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteEditInfo>(
          RemoteEditInfo.$_createMessage);
  static RemoteEditInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get insert => $_getIZ(0);
  @$pb.TagNumber(1)
  set insert($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInsert() => $_has(0);
  @$pb.TagNumber(1)
  void clearInsert() => $_clearField(1);

  @$pb.TagNumber(2)
  RemoteImeObject get textFieldStatus => $_getN(1);
  @$pb.TagNumber(2)
  set textFieldStatus(RemoteImeObject value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTextFieldStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearTextFieldStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  RemoteImeObject ensureTextFieldStatus() => $_ensure(1);
}

class RemoteImeObject extends $pb.GeneratedMessage {
  factory RemoteImeObject({
    $core.int? start,
    $core.int? end,
    $core.String? value,
  }) {
    final result = RemoteImeObject._();
    if (start != null) result.start = start;
    if (end != null) result.end = end;
    if (value != null) result.value = value;
    return result;
  }

  RemoteImeObject._();

  factory RemoteImeObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeObject()..mergeFromBuffer(data, registry);
  factory RemoteImeObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeObject()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteImeObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteImeObject.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'start')
    ..aI(2, _omitFieldNames ? '' : 'end')
    ..aOS(3, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeObject copyWith(void Function(RemoteImeObject) updates) =>
      super.copyWith((message) => updates(message as RemoteImeObject))
          as RemoteImeObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteImeObject() / RemoteImeObject.new instead')
  static RemoteImeObject create() => RemoteImeObject._();
  static $pb.GeneratedMessage $_createMessage() => RemoteImeObject._();
  @$core.override
  RemoteImeObject createEmptyInstance() => RemoteImeObject._();
  @$core.pragma('dart2js:noInline')
  static RemoteImeObject getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteImeObject>(
          RemoteImeObject.$_createMessage);
  static RemoteImeObject? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get start => $_getIZ(0);
  @$pb.TagNumber(1)
  set start($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStart() => $_has(0);
  @$pb.TagNumber(1)
  void clearStart() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get end => $_getIZ(1);
  @$pb.TagNumber(2)
  set end($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnd() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnd() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get value => $_getSZ(2);
  @$pb.TagNumber(3)
  set value($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearValue() => $_clearField(3);
}

class RemoteImeBatchEdit extends $pb.GeneratedMessage {
  factory RemoteImeBatchEdit({
    $core.int? imeCounter,
    $core.int? fieldCounter,
    $core.Iterable<RemoteEditInfo>? editInfo,
  }) {
    final result = RemoteImeBatchEdit._();
    if (imeCounter != null) result.imeCounter = imeCounter;
    if (fieldCounter != null) result.fieldCounter = fieldCounter;
    if (editInfo != null) result.editInfo.addAll(editInfo);
    return result;
  }

  RemoteImeBatchEdit._();

  factory RemoteImeBatchEdit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeBatchEdit()..mergeFromBuffer(data, registry);
  factory RemoteImeBatchEdit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeBatchEdit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteImeBatchEdit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteImeBatchEdit.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'imeCounter')
    ..aI(2, _omitFieldNames ? '' : 'fieldCounter')
    ..pPM<RemoteEditInfo>(3, _omitFieldNames ? '' : 'editInfo',
        subBuilder: RemoteEditInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeBatchEdit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeBatchEdit copyWith(void Function(RemoteImeBatchEdit) updates) =>
      super.copyWith((message) => updates(message as RemoteImeBatchEdit))
          as RemoteImeBatchEdit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteImeBatchEdit() / RemoteImeBatchEdit.new instead')
  static RemoteImeBatchEdit create() => RemoteImeBatchEdit._();
  static $pb.GeneratedMessage $_createMessage() => RemoteImeBatchEdit._();
  @$core.override
  RemoteImeBatchEdit createEmptyInstance() => RemoteImeBatchEdit._();
  @$core.pragma('dart2js:noInline')
  static RemoteImeBatchEdit getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteImeBatchEdit>(
          RemoteImeBatchEdit.$_createMessage);
  static RemoteImeBatchEdit? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get imeCounter => $_getIZ(0);
  @$pb.TagNumber(1)
  set imeCounter($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImeCounter() => $_has(0);
  @$pb.TagNumber(1)
  void clearImeCounter() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get fieldCounter => $_getIZ(1);
  @$pb.TagNumber(2)
  set fieldCounter($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFieldCounter() => $_has(1);
  @$pb.TagNumber(2)
  void clearFieldCounter() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<RemoteEditInfo> get editInfo => $_getList(2);
}

class RemoteAppInfo extends $pb.GeneratedMessage {
  factory RemoteAppInfo({
    $core.int? counter,
    $core.int? int2,
    $core.int? int3,
    $core.String? int4,
    $core.int? int7,
    $core.int? int8,
    $core.String? label,
    $core.String? appPackage,
    $core.int? int13,
  }) {
    final result = RemoteAppInfo._();
    if (counter != null) result.counter = counter;
    if (int2 != null) result.int2 = int2;
    if (int3 != null) result.int3 = int3;
    if (int4 != null) result.int4 = int4;
    if (int7 != null) result.int7 = int7;
    if (int8 != null) result.int8 = int8;
    if (label != null) result.label = label;
    if (appPackage != null) result.appPackage = appPackage;
    if (int13 != null) result.int13 = int13;
    return result;
  }

  RemoteAppInfo._();

  factory RemoteAppInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteAppInfo()..mergeFromBuffer(data, registry);
  factory RemoteAppInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteAppInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteAppInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteAppInfo.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'counter')
    ..aI(2, _omitFieldNames ? '' : 'int2')
    ..aI(3, _omitFieldNames ? '' : 'int3')
    ..aOS(4, _omitFieldNames ? '' : 'int4')
    ..aI(7, _omitFieldNames ? '' : 'int7')
    ..aI(8, _omitFieldNames ? '' : 'int8')
    ..aOS(10, _omitFieldNames ? '' : 'label')
    ..aOS(12, _omitFieldNames ? '' : 'appPackage')
    ..aI(13, _omitFieldNames ? '' : 'int13')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteAppInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteAppInfo copyWith(void Function(RemoteAppInfo) updates) =>
      super.copyWith((message) => updates(message as RemoteAppInfo))
          as RemoteAppInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteAppInfo() / RemoteAppInfo.new instead')
  static RemoteAppInfo create() => RemoteAppInfo._();
  static $pb.GeneratedMessage $_createMessage() => RemoteAppInfo._();
  @$core.override
  RemoteAppInfo createEmptyInstance() => RemoteAppInfo._();
  @$core.pragma('dart2js:noInline')
  static RemoteAppInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteAppInfo>(
          RemoteAppInfo.$_createMessage);
  static RemoteAppInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get counter => $_getIZ(0);
  @$pb.TagNumber(1)
  set counter($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCounter() => $_has(0);
  @$pb.TagNumber(1)
  void clearCounter() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get int2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set int2($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInt2() => $_has(1);
  @$pb.TagNumber(2)
  void clearInt2() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get int3 => $_getIZ(2);
  @$pb.TagNumber(3)
  set int3($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInt3() => $_has(2);
  @$pb.TagNumber(3)
  void clearInt3() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get int4 => $_getSZ(3);
  @$pb.TagNumber(4)
  set int4($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInt4() => $_has(3);
  @$pb.TagNumber(4)
  void clearInt4() => $_clearField(4);

  @$pb.TagNumber(7)
  $core.int get int7 => $_getIZ(4);
  @$pb.TagNumber(7)
  set int7($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(7)
  $core.bool hasInt7() => $_has(4);
  @$pb.TagNumber(7)
  void clearInt7() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get int8 => $_getIZ(5);
  @$pb.TagNumber(8)
  set int8($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(8)
  $core.bool hasInt8() => $_has(5);
  @$pb.TagNumber(8)
  void clearInt8() => $_clearField(8);

  @$pb.TagNumber(10)
  $core.String get label => $_getSZ(6);
  @$pb.TagNumber(10)
  set label($core.String value) => $_setString(6, value);
  @$pb.TagNumber(10)
  $core.bool hasLabel() => $_has(6);
  @$pb.TagNumber(10)
  void clearLabel() => $_clearField(10);

  @$pb.TagNumber(12)
  $core.String get appPackage => $_getSZ(7);
  @$pb.TagNumber(12)
  set appPackage($core.String value) => $_setString(7, value);
  @$pb.TagNumber(12)
  $core.bool hasAppPackage() => $_has(7);
  @$pb.TagNumber(12)
  void clearAppPackage() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get int13 => $_getIZ(8);
  @$pb.TagNumber(13)
  set int13($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(13)
  $core.bool hasInt13() => $_has(8);
  @$pb.TagNumber(13)
  void clearInt13() => $_clearField(13);
}

class RemoteImeKeyInject extends $pb.GeneratedMessage {
  factory RemoteImeKeyInject({
    RemoteAppInfo? appInfo,
    RemoteTextFieldStatus? textFieldStatus,
  }) {
    final result = RemoteImeKeyInject._();
    if (appInfo != null) result.appInfo = appInfo;
    if (textFieldStatus != null) result.textFieldStatus = textFieldStatus;
    return result;
  }

  RemoteImeKeyInject._();

  factory RemoteImeKeyInject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeKeyInject()..mergeFromBuffer(data, registry);
  factory RemoteImeKeyInject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteImeKeyInject()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteImeKeyInject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteImeKeyInject.$_createMessage)
    ..aOM<RemoteAppInfo>(1, _omitFieldNames ? '' : 'appInfo',
        subBuilder: RemoteAppInfo.$_createMessage)
    ..aOM<RemoteTextFieldStatus>(2, _omitFieldNames ? '' : 'textFieldStatus',
        subBuilder: RemoteTextFieldStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeKeyInject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteImeKeyInject copyWith(void Function(RemoteImeKeyInject) updates) =>
      super.copyWith((message) => updates(message as RemoteImeKeyInject))
          as RemoteImeKeyInject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteImeKeyInject() / RemoteImeKeyInject.new instead')
  static RemoteImeKeyInject create() => RemoteImeKeyInject._();
  static $pb.GeneratedMessage $_createMessage() => RemoteImeKeyInject._();
  @$core.override
  RemoteImeKeyInject createEmptyInstance() => RemoteImeKeyInject._();
  @$core.pragma('dart2js:noInline')
  static RemoteImeKeyInject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoteImeKeyInject>(
          RemoteImeKeyInject.$_createMessage);
  static RemoteImeKeyInject? _defaultInstance;

  @$pb.TagNumber(1)
  RemoteAppInfo get appInfo => $_getN(0);
  @$pb.TagNumber(1)
  set appInfo(RemoteAppInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAppInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  RemoteAppInfo ensureAppInfo() => $_ensure(0);

  @$pb.TagNumber(2)
  RemoteTextFieldStatus get textFieldStatus => $_getN(1);
  @$pb.TagNumber(2)
  set textFieldStatus(RemoteTextFieldStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTextFieldStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearTextFieldStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  RemoteTextFieldStatus ensureTextFieldStatus() => $_ensure(1);
}

class RemoteKeyInject extends $pb.GeneratedMessage {
  factory RemoteKeyInject({
    RemoteKeyCode? keyCode,
    RemoteDirection? direction,
  }) {
    final result = RemoteKeyInject._();
    if (keyCode != null) result.keyCode = keyCode;
    if (direction != null) result.direction = direction;
    return result;
  }

  RemoteKeyInject._();

  factory RemoteKeyInject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteKeyInject()..mergeFromBuffer(data, registry);
  factory RemoteKeyInject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteKeyInject()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteKeyInject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteKeyInject.$_createMessage)
    ..aE<RemoteKeyCode>(1, _omitFieldNames ? '' : 'keyCode',
        enumValues: RemoteKeyCode.values)
    ..aE<RemoteDirection>(2, _omitFieldNames ? '' : 'direction',
        enumValues: RemoteDirection.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteKeyInject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteKeyInject copyWith(void Function(RemoteKeyInject) updates) =>
      super.copyWith((message) => updates(message as RemoteKeyInject))
          as RemoteKeyInject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteKeyInject() / RemoteKeyInject.new instead')
  static RemoteKeyInject create() => RemoteKeyInject._();
  static $pb.GeneratedMessage $_createMessage() => RemoteKeyInject._();
  @$core.override
  RemoteKeyInject createEmptyInstance() => RemoteKeyInject._();
  @$core.pragma('dart2js:noInline')
  static RemoteKeyInject getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteKeyInject>(
          RemoteKeyInject.$_createMessage);
  static RemoteKeyInject? _defaultInstance;

  @$pb.TagNumber(1)
  RemoteKeyCode get keyCode => $_getN(0);
  @$pb.TagNumber(1)
  set keyCode(RemoteKeyCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyCode() => $_clearField(1);

  @$pb.TagNumber(2)
  RemoteDirection get direction => $_getN(1);
  @$pb.TagNumber(2)
  set direction(RemoteDirection value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDirection() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirection() => $_clearField(2);
}

class RemotePingResponse extends $pb.GeneratedMessage {
  factory RemotePingResponse({
    $core.int? val1,
  }) {
    final result = RemotePingResponse._();
    if (val1 != null) result.val1 = val1;
    return result;
  }

  RemotePingResponse._();

  factory RemotePingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemotePingResponse()..mergeFromBuffer(data, registry);
  factory RemotePingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemotePingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemotePingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemotePingResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'val1')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemotePingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemotePingResponse copyWith(void Function(RemotePingResponse) updates) =>
      super.copyWith((message) => updates(message as RemotePingResponse))
          as RemotePingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemotePingResponse() / RemotePingResponse.new instead')
  static RemotePingResponse create() => RemotePingResponse._();
  static $pb.GeneratedMessage $_createMessage() => RemotePingResponse._();
  @$core.override
  RemotePingResponse createEmptyInstance() => RemotePingResponse._();
  @$core.pragma('dart2js:noInline')
  static RemotePingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemotePingResponse>(
          RemotePingResponse.$_createMessage);
  static RemotePingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get val1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set val1($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVal1() => $_has(0);
  @$pb.TagNumber(1)
  void clearVal1() => $_clearField(1);
}

class RemotePingRequest extends $pb.GeneratedMessage {
  factory RemotePingRequest({
    $core.int? val1,
    $core.int? val2,
  }) {
    final result = RemotePingRequest._();
    if (val1 != null) result.val1 = val1;
    if (val2 != null) result.val2 = val2;
    return result;
  }

  RemotePingRequest._();

  factory RemotePingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemotePingRequest()..mergeFromBuffer(data, registry);
  factory RemotePingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemotePingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemotePingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemotePingRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'val1')
    ..aI(2, _omitFieldNames ? '' : 'val2')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemotePingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemotePingRequest copyWith(void Function(RemotePingRequest) updates) =>
      super.copyWith((message) => updates(message as RemotePingRequest))
          as RemotePingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemotePingRequest() / RemotePingRequest.new instead')
  static RemotePingRequest create() => RemotePingRequest._();
  static $pb.GeneratedMessage $_createMessage() => RemotePingRequest._();
  @$core.override
  RemotePingRequest createEmptyInstance() => RemotePingRequest._();
  @$core.pragma('dart2js:noInline')
  static RemotePingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemotePingRequest>(
          RemotePingRequest.$_createMessage);
  static RemotePingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get val1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set val1($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVal1() => $_has(0);
  @$pb.TagNumber(1)
  void clearVal1() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get val2 => $_getIZ(1);
  @$pb.TagNumber(2)
  set val2($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVal2() => $_has(1);
  @$pb.TagNumber(2)
  void clearVal2() => $_clearField(2);
}

class RemoteSetActive extends $pb.GeneratedMessage {
  factory RemoteSetActive({
    $core.int? active,
  }) {
    final result = RemoteSetActive._();
    if (active != null) result.active = active;
    return result;
  }

  RemoteSetActive._();

  factory RemoteSetActive.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSetActive()..mergeFromBuffer(data, registry);
  factory RemoteSetActive.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteSetActive()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteSetActive',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteSetActive.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'active')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSetActive clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteSetActive copyWith(void Function(RemoteSetActive) updates) =>
      super.copyWith((message) => updates(message as RemoteSetActive))
          as RemoteSetActive;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteSetActive() / RemoteSetActive.new instead')
  static RemoteSetActive create() => RemoteSetActive._();
  static $pb.GeneratedMessage $_createMessage() => RemoteSetActive._();
  @$core.override
  RemoteSetActive createEmptyInstance() => RemoteSetActive._();
  @$core.pragma('dart2js:noInline')
  static RemoteSetActive getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteSetActive>(
          RemoteSetActive.$_createMessage);
  static RemoteSetActive? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get active => $_getIZ(0);
  @$pb.TagNumber(1)
  set active($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActive() => $_has(0);
  @$pb.TagNumber(1)
  void clearActive() => $_clearField(1);
}

class RemoteDeviceInfo extends $pb.GeneratedMessage {
  factory RemoteDeviceInfo({
    $core.String? model,
    $core.String? vendor,
    $core.int? unknown1,
    $core.String? unknown2,
    $core.String? packageName,
    $core.String? appVersion,
  }) {
    final result = RemoteDeviceInfo._();
    if (model != null) result.model = model;
    if (vendor != null) result.vendor = vendor;
    if (unknown1 != null) result.unknown1 = unknown1;
    if (unknown2 != null) result.unknown2 = unknown2;
    if (packageName != null) result.packageName = packageName;
    if (appVersion != null) result.appVersion = appVersion;
    return result;
  }

  RemoteDeviceInfo._();

  factory RemoteDeviceInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteDeviceInfo()..mergeFromBuffer(data, registry);
  factory RemoteDeviceInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteDeviceInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteDeviceInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteDeviceInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'model')
    ..aOS(2, _omitFieldNames ? '' : 'vendor')
    ..aI(3, _omitFieldNames ? '' : 'unknown1')
    ..aOS(4, _omitFieldNames ? '' : 'unknown2')
    ..aOS(5, _omitFieldNames ? '' : 'packageName')
    ..aOS(6, _omitFieldNames ? '' : 'appVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteDeviceInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteDeviceInfo copyWith(void Function(RemoteDeviceInfo) updates) =>
      super.copyWith((message) => updates(message as RemoteDeviceInfo))
          as RemoteDeviceInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteDeviceInfo() / RemoteDeviceInfo.new instead')
  static RemoteDeviceInfo create() => RemoteDeviceInfo._();
  static $pb.GeneratedMessage $_createMessage() => RemoteDeviceInfo._();
  @$core.override
  RemoteDeviceInfo createEmptyInstance() => RemoteDeviceInfo._();
  @$core.pragma('dart2js:noInline')
  static RemoteDeviceInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteDeviceInfo>(
          RemoteDeviceInfo.$_createMessage);
  static RemoteDeviceInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get model => $_getSZ(0);
  @$pb.TagNumber(1)
  set model($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModel() => $_has(0);
  @$pb.TagNumber(1)
  void clearModel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get vendor => $_getSZ(1);
  @$pb.TagNumber(2)
  set vendor($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVendor() => $_has(1);
  @$pb.TagNumber(2)
  void clearVendor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get unknown1 => $_getIZ(2);
  @$pb.TagNumber(3)
  set unknown1($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUnknown1() => $_has(2);
  @$pb.TagNumber(3)
  void clearUnknown1() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get unknown2 => $_getSZ(3);
  @$pb.TagNumber(4)
  set unknown2($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUnknown2() => $_has(3);
  @$pb.TagNumber(4)
  void clearUnknown2() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get packageName => $_getSZ(4);
  @$pb.TagNumber(5)
  set packageName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPackageName() => $_has(4);
  @$pb.TagNumber(5)
  void clearPackageName() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get appVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set appVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAppVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearAppVersion() => $_clearField(6);
}

class RemoteConfigure extends $pb.GeneratedMessage {
  factory RemoteConfigure({
    $core.int? code1,
    RemoteDeviceInfo? deviceInfo,
  }) {
    final result = RemoteConfigure._();
    if (code1 != null) result.code1 = code1;
    if (deviceInfo != null) result.deviceInfo = deviceInfo;
    return result;
  }

  RemoteConfigure._();

  factory RemoteConfigure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteConfigure()..mergeFromBuffer(data, registry);
  factory RemoteConfigure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteConfigure()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteConfigure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteConfigure.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'code1')
    ..aOM<RemoteDeviceInfo>(2, _omitFieldNames ? '' : 'deviceInfo',
        subBuilder: RemoteDeviceInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteConfigure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteConfigure copyWith(void Function(RemoteConfigure) updates) =>
      super.copyWith((message) => updates(message as RemoteConfigure))
          as RemoteConfigure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteConfigure() / RemoteConfigure.new instead')
  static RemoteConfigure create() => RemoteConfigure._();
  static $pb.GeneratedMessage $_createMessage() => RemoteConfigure._();
  @$core.override
  RemoteConfigure createEmptyInstance() => RemoteConfigure._();
  @$core.pragma('dart2js:noInline')
  static RemoteConfigure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteConfigure>(
          RemoteConfigure.$_createMessage);
  static RemoteConfigure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get code1 => $_getIZ(0);
  @$pb.TagNumber(1)
  set code1($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCode1() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode1() => $_clearField(1);

  @$pb.TagNumber(2)
  RemoteDeviceInfo get deviceInfo => $_getN(1);
  @$pb.TagNumber(2)
  set deviceInfo(RemoteDeviceInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  RemoteDeviceInfo ensureDeviceInfo() => $_ensure(1);
}

class RemoteError extends $pb.GeneratedMessage {
  factory RemoteError({
    $core.bool? value,
    RemoteMessage? message,
  }) {
    final result = RemoteError._();
    if (value != null) result.value = value;
    if (message != null) result.message = message;
    return result;
  }

  RemoteError._();

  factory RemoteError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteError()..mergeFromBuffer(data, registry);
  factory RemoteError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteError()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteError.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'value')
    ..aOM<RemoteMessage>(2, _omitFieldNames ? '' : 'message',
        subBuilder: RemoteMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteError copyWith(void Function(RemoteError) updates) =>
      super.copyWith((message) => updates(message as RemoteError))
          as RemoteError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteError() / RemoteError.new instead')
  static RemoteError create() => RemoteError._();
  static $pb.GeneratedMessage $_createMessage() => RemoteError._();
  @$core.override
  RemoteError createEmptyInstance() => RemoteError._();
  @$core.pragma('dart2js:noInline')
  static RemoteError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteError>(
          RemoteError.$_createMessage);
  static RemoteError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get value => $_getBF(0);
  @$pb.TagNumber(1)
  set value($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  RemoteMessage get message => $_getN(1);
  @$pb.TagNumber(2)
  set message(RemoteMessage value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
  @$pb.TagNumber(2)
  RemoteMessage ensureMessage() => $_ensure(1);
}

class RemoteMessage extends $pb.GeneratedMessage {
  factory RemoteMessage({
    RemoteConfigure? remoteConfigure,
    RemoteSetActive? remoteSetActive,
    RemoteError? remoteError,
    RemotePingRequest? remotePingRequest,
    RemotePingResponse? remotePingResponse,
    RemoteKeyInject? remoteKeyInject,
    RemoteImeKeyInject? remoteImeKeyInject,
    RemoteImeBatchEdit? remoteImeBatchEdit,
    RemoteImeShowRequest? remoteImeShowRequest,
    RemoteVoiceBegin? remoteVoiceBegin,
    RemoteVoicePayload? remoteVoicePayload,
    RemoteVoiceEnd? remoteVoiceEnd,
    RemoteStart? remoteStart,
    RemoteSetVolumeLevel? remoteSetVolumeLevel,
    RemoteAdjustVolumeLevel? remoteAdjustVolumeLevel,
    RemoteSetPreferredAudioDevice? remoteSetPreferredAudioDevice,
    RemoteResetPreferredAudioDevice? remoteResetPreferredAudioDevice,
    RemoteAppLinkLaunchRequest? remoteAppLinkLaunchRequest,
  }) {
    final result = RemoteMessage._();
    if (remoteConfigure != null) result.remoteConfigure = remoteConfigure;
    if (remoteSetActive != null) result.remoteSetActive = remoteSetActive;
    if (remoteError != null) result.remoteError = remoteError;
    if (remotePingRequest != null) result.remotePingRequest = remotePingRequest;
    if (remotePingResponse != null)
      result.remotePingResponse = remotePingResponse;
    if (remoteKeyInject != null) result.remoteKeyInject = remoteKeyInject;
    if (remoteImeKeyInject != null)
      result.remoteImeKeyInject = remoteImeKeyInject;
    if (remoteImeBatchEdit != null)
      result.remoteImeBatchEdit = remoteImeBatchEdit;
    if (remoteImeShowRequest != null)
      result.remoteImeShowRequest = remoteImeShowRequest;
    if (remoteVoiceBegin != null) result.remoteVoiceBegin = remoteVoiceBegin;
    if (remoteVoicePayload != null)
      result.remoteVoicePayload = remoteVoicePayload;
    if (remoteVoiceEnd != null) result.remoteVoiceEnd = remoteVoiceEnd;
    if (remoteStart != null) result.remoteStart = remoteStart;
    if (remoteSetVolumeLevel != null)
      result.remoteSetVolumeLevel = remoteSetVolumeLevel;
    if (remoteAdjustVolumeLevel != null)
      result.remoteAdjustVolumeLevel = remoteAdjustVolumeLevel;
    if (remoteSetPreferredAudioDevice != null)
      result.remoteSetPreferredAudioDevice = remoteSetPreferredAudioDevice;
    if (remoteResetPreferredAudioDevice != null)
      result.remoteResetPreferredAudioDevice = remoteResetPreferredAudioDevice;
    if (remoteAppLinkLaunchRequest != null)
      result.remoteAppLinkLaunchRequest = remoteAppLinkLaunchRequest;
    return result;
  }

  RemoteMessage._();

  factory RemoteMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteMessage()..mergeFromBuffer(data, registry);
  factory RemoteMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RemoteMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoteMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'remote'),
      createEmptyInstance: RemoteMessage.$_createMessage)
    ..aOM<RemoteConfigure>(1, _omitFieldNames ? '' : 'remoteConfigure',
        subBuilder: RemoteConfigure.$_createMessage)
    ..aOM<RemoteSetActive>(2, _omitFieldNames ? '' : 'remoteSetActive',
        subBuilder: RemoteSetActive.$_createMessage)
    ..aOM<RemoteError>(3, _omitFieldNames ? '' : 'remoteError',
        subBuilder: RemoteError.$_createMessage)
    ..aOM<RemotePingRequest>(8, _omitFieldNames ? '' : 'remotePingRequest',
        subBuilder: RemotePingRequest.$_createMessage)
    ..aOM<RemotePingResponse>(9, _omitFieldNames ? '' : 'remotePingResponse',
        subBuilder: RemotePingResponse.$_createMessage)
    ..aOM<RemoteKeyInject>(10, _omitFieldNames ? '' : 'remoteKeyInject',
        subBuilder: RemoteKeyInject.$_createMessage)
    ..aOM<RemoteImeKeyInject>(20, _omitFieldNames ? '' : 'remoteImeKeyInject',
        subBuilder: RemoteImeKeyInject.$_createMessage)
    ..aOM<RemoteImeBatchEdit>(21, _omitFieldNames ? '' : 'remoteImeBatchEdit',
        subBuilder: RemoteImeBatchEdit.$_createMessage)
    ..aOM<RemoteImeShowRequest>(
        22, _omitFieldNames ? '' : 'remoteImeShowRequest',
        subBuilder: RemoteImeShowRequest.$_createMessage)
    ..aOM<RemoteVoiceBegin>(30, _omitFieldNames ? '' : 'remoteVoiceBegin',
        subBuilder: RemoteVoiceBegin.$_createMessage)
    ..aOM<RemoteVoicePayload>(31, _omitFieldNames ? '' : 'remoteVoicePayload',
        subBuilder: RemoteVoicePayload.$_createMessage)
    ..aOM<RemoteVoiceEnd>(32, _omitFieldNames ? '' : 'remoteVoiceEnd',
        subBuilder: RemoteVoiceEnd.$_createMessage)
    ..aOM<RemoteStart>(40, _omitFieldNames ? '' : 'remoteStart',
        subBuilder: RemoteStart.$_createMessage)
    ..aOM<RemoteSetVolumeLevel>(
        50, _omitFieldNames ? '' : 'remoteSetVolumeLevel',
        subBuilder: RemoteSetVolumeLevel.$_createMessage)
    ..aOM<RemoteAdjustVolumeLevel>(
        51, _omitFieldNames ? '' : 'remoteAdjustVolumeLevel',
        subBuilder: RemoteAdjustVolumeLevel.$_createMessage)
    ..aOM<RemoteSetPreferredAudioDevice>(
        60, _omitFieldNames ? '' : 'remoteSetPreferredAudioDevice',
        subBuilder: RemoteSetPreferredAudioDevice.$_createMessage)
    ..aOM<RemoteResetPreferredAudioDevice>(
        61, _omitFieldNames ? '' : 'remoteResetPreferredAudioDevice',
        subBuilder: RemoteResetPreferredAudioDevice.$_createMessage)
    ..aOM<RemoteAppLinkLaunchRequest>(
        90, _omitFieldNames ? '' : 'remoteAppLinkLaunchRequest',
        subBuilder: RemoteAppLinkLaunchRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoteMessage copyWith(void Function(RemoteMessage) updates) =>
      super.copyWith((message) => updates(message as RemoteMessage))
          as RemoteMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RemoteMessage() / RemoteMessage.new instead')
  static RemoteMessage create() => RemoteMessage._();
  static $pb.GeneratedMessage $_createMessage() => RemoteMessage._();
  @$core.override
  RemoteMessage createEmptyInstance() => RemoteMessage._();
  @$core.pragma('dart2js:noInline')
  static RemoteMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RemoteMessage>(
          RemoteMessage.$_createMessage);
  static RemoteMessage? _defaultInstance;

  @$pb.TagNumber(1)
  RemoteConfigure get remoteConfigure => $_getN(0);
  @$pb.TagNumber(1)
  set remoteConfigure(RemoteConfigure value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRemoteConfigure() => $_has(0);
  @$pb.TagNumber(1)
  void clearRemoteConfigure() => $_clearField(1);
  @$pb.TagNumber(1)
  RemoteConfigure ensureRemoteConfigure() => $_ensure(0);

  @$pb.TagNumber(2)
  RemoteSetActive get remoteSetActive => $_getN(1);
  @$pb.TagNumber(2)
  set remoteSetActive(RemoteSetActive value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRemoteSetActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemoteSetActive() => $_clearField(2);
  @$pb.TagNumber(2)
  RemoteSetActive ensureRemoteSetActive() => $_ensure(1);

  @$pb.TagNumber(3)
  RemoteError get remoteError => $_getN(2);
  @$pb.TagNumber(3)
  set remoteError(RemoteError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRemoteError() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemoteError() => $_clearField(3);
  @$pb.TagNumber(3)
  RemoteError ensureRemoteError() => $_ensure(2);

  @$pb.TagNumber(8)
  RemotePingRequest get remotePingRequest => $_getN(3);
  @$pb.TagNumber(8)
  set remotePingRequest(RemotePingRequest value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasRemotePingRequest() => $_has(3);
  @$pb.TagNumber(8)
  void clearRemotePingRequest() => $_clearField(8);
  @$pb.TagNumber(8)
  RemotePingRequest ensureRemotePingRequest() => $_ensure(3);

  @$pb.TagNumber(9)
  RemotePingResponse get remotePingResponse => $_getN(4);
  @$pb.TagNumber(9)
  set remotePingResponse(RemotePingResponse value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasRemotePingResponse() => $_has(4);
  @$pb.TagNumber(9)
  void clearRemotePingResponse() => $_clearField(9);
  @$pb.TagNumber(9)
  RemotePingResponse ensureRemotePingResponse() => $_ensure(4);

  @$pb.TagNumber(10)
  RemoteKeyInject get remoteKeyInject => $_getN(5);
  @$pb.TagNumber(10)
  set remoteKeyInject(RemoteKeyInject value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRemoteKeyInject() => $_has(5);
  @$pb.TagNumber(10)
  void clearRemoteKeyInject() => $_clearField(10);
  @$pb.TagNumber(10)
  RemoteKeyInject ensureRemoteKeyInject() => $_ensure(5);

  @$pb.TagNumber(20)
  RemoteImeKeyInject get remoteImeKeyInject => $_getN(6);
  @$pb.TagNumber(20)
  set remoteImeKeyInject(RemoteImeKeyInject value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasRemoteImeKeyInject() => $_has(6);
  @$pb.TagNumber(20)
  void clearRemoteImeKeyInject() => $_clearField(20);
  @$pb.TagNumber(20)
  RemoteImeKeyInject ensureRemoteImeKeyInject() => $_ensure(6);

  @$pb.TagNumber(21)
  RemoteImeBatchEdit get remoteImeBatchEdit => $_getN(7);
  @$pb.TagNumber(21)
  set remoteImeBatchEdit(RemoteImeBatchEdit value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasRemoteImeBatchEdit() => $_has(7);
  @$pb.TagNumber(21)
  void clearRemoteImeBatchEdit() => $_clearField(21);
  @$pb.TagNumber(21)
  RemoteImeBatchEdit ensureRemoteImeBatchEdit() => $_ensure(7);

  @$pb.TagNumber(22)
  RemoteImeShowRequest get remoteImeShowRequest => $_getN(8);
  @$pb.TagNumber(22)
  set remoteImeShowRequest(RemoteImeShowRequest value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasRemoteImeShowRequest() => $_has(8);
  @$pb.TagNumber(22)
  void clearRemoteImeShowRequest() => $_clearField(22);
  @$pb.TagNumber(22)
  RemoteImeShowRequest ensureRemoteImeShowRequest() => $_ensure(8);

  @$pb.TagNumber(30)
  RemoteVoiceBegin get remoteVoiceBegin => $_getN(9);
  @$pb.TagNumber(30)
  set remoteVoiceBegin(RemoteVoiceBegin value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasRemoteVoiceBegin() => $_has(9);
  @$pb.TagNumber(30)
  void clearRemoteVoiceBegin() => $_clearField(30);
  @$pb.TagNumber(30)
  RemoteVoiceBegin ensureRemoteVoiceBegin() => $_ensure(9);

  @$pb.TagNumber(31)
  RemoteVoicePayload get remoteVoicePayload => $_getN(10);
  @$pb.TagNumber(31)
  set remoteVoicePayload(RemoteVoicePayload value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasRemoteVoicePayload() => $_has(10);
  @$pb.TagNumber(31)
  void clearRemoteVoicePayload() => $_clearField(31);
  @$pb.TagNumber(31)
  RemoteVoicePayload ensureRemoteVoicePayload() => $_ensure(10);

  @$pb.TagNumber(32)
  RemoteVoiceEnd get remoteVoiceEnd => $_getN(11);
  @$pb.TagNumber(32)
  set remoteVoiceEnd(RemoteVoiceEnd value) => $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasRemoteVoiceEnd() => $_has(11);
  @$pb.TagNumber(32)
  void clearRemoteVoiceEnd() => $_clearField(32);
  @$pb.TagNumber(32)
  RemoteVoiceEnd ensureRemoteVoiceEnd() => $_ensure(11);

  @$pb.TagNumber(40)
  RemoteStart get remoteStart => $_getN(12);
  @$pb.TagNumber(40)
  set remoteStart(RemoteStart value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasRemoteStart() => $_has(12);
  @$pb.TagNumber(40)
  void clearRemoteStart() => $_clearField(40);
  @$pb.TagNumber(40)
  RemoteStart ensureRemoteStart() => $_ensure(12);

  @$pb.TagNumber(50)
  RemoteSetVolumeLevel get remoteSetVolumeLevel => $_getN(13);
  @$pb.TagNumber(50)
  set remoteSetVolumeLevel(RemoteSetVolumeLevel value) => $_setField(50, value);
  @$pb.TagNumber(50)
  $core.bool hasRemoteSetVolumeLevel() => $_has(13);
  @$pb.TagNumber(50)
  void clearRemoteSetVolumeLevel() => $_clearField(50);
  @$pb.TagNumber(50)
  RemoteSetVolumeLevel ensureRemoteSetVolumeLevel() => $_ensure(13);

  @$pb.TagNumber(51)
  RemoteAdjustVolumeLevel get remoteAdjustVolumeLevel => $_getN(14);
  @$pb.TagNumber(51)
  set remoteAdjustVolumeLevel(RemoteAdjustVolumeLevel value) =>
      $_setField(51, value);
  @$pb.TagNumber(51)
  $core.bool hasRemoteAdjustVolumeLevel() => $_has(14);
  @$pb.TagNumber(51)
  void clearRemoteAdjustVolumeLevel() => $_clearField(51);
  @$pb.TagNumber(51)
  RemoteAdjustVolumeLevel ensureRemoteAdjustVolumeLevel() => $_ensure(14);

  @$pb.TagNumber(60)
  RemoteSetPreferredAudioDevice get remoteSetPreferredAudioDevice => $_getN(15);
  @$pb.TagNumber(60)
  set remoteSetPreferredAudioDevice(RemoteSetPreferredAudioDevice value) =>
      $_setField(60, value);
  @$pb.TagNumber(60)
  $core.bool hasRemoteSetPreferredAudioDevice() => $_has(15);
  @$pb.TagNumber(60)
  void clearRemoteSetPreferredAudioDevice() => $_clearField(60);
  @$pb.TagNumber(60)
  RemoteSetPreferredAudioDevice ensureRemoteSetPreferredAudioDevice() =>
      $_ensure(15);

  @$pb.TagNumber(61)
  RemoteResetPreferredAudioDevice get remoteResetPreferredAudioDevice =>
      $_getN(16);
  @$pb.TagNumber(61)
  set remoteResetPreferredAudioDevice(RemoteResetPreferredAudioDevice value) =>
      $_setField(61, value);
  @$pb.TagNumber(61)
  $core.bool hasRemoteResetPreferredAudioDevice() => $_has(16);
  @$pb.TagNumber(61)
  void clearRemoteResetPreferredAudioDevice() => $_clearField(61);
  @$pb.TagNumber(61)
  RemoteResetPreferredAudioDevice ensureRemoteResetPreferredAudioDevice() =>
      $_ensure(16);

  @$pb.TagNumber(90)
  RemoteAppLinkLaunchRequest get remoteAppLinkLaunchRequest => $_getN(17);
  @$pb.TagNumber(90)
  set remoteAppLinkLaunchRequest(RemoteAppLinkLaunchRequest value) =>
      $_setField(90, value);
  @$pb.TagNumber(90)
  $core.bool hasRemoteAppLinkLaunchRequest() => $_has(17);
  @$pb.TagNumber(90)
  void clearRemoteAppLinkLaunchRequest() => $_clearField(90);
  @$pb.TagNumber(90)
  RemoteAppLinkLaunchRequest ensureRemoteAppLinkLaunchRequest() => $_ensure(17);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
