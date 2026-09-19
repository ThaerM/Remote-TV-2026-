// This is a generated file - do not edit.
//
// Generated from polo.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'polo.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'polo.pbenum.dart';

class OuterMessage extends $pb.GeneratedMessage {
  factory OuterMessage({
    $core.int? protocolVersion,
    OuterMessage_Status? status,
    PairingRequest? pairingRequest,
    PairingRequestAck? pairingRequestAck,
    Options? options,
    Configuration? configuration,
    ConfigurationAck? configurationAck,
    Secret? secret,
    SecretAck? secretAck,
  }) {
    final result = OuterMessage._();
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (status != null) result.status = status;
    if (pairingRequest != null) result.pairingRequest = pairingRequest;
    if (pairingRequestAck != null) result.pairingRequestAck = pairingRequestAck;
    if (options != null) result.options = options;
    if (configuration != null) result.configuration = configuration;
    if (configurationAck != null) result.configurationAck = configurationAck;
    if (secret != null) result.secret = secret;
    if (secretAck != null) result.secretAck = secretAck;
    return result;
  }

  OuterMessage._();

  factory OuterMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OuterMessage()..mergeFromBuffer(data, registry);
  factory OuterMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OuterMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OuterMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: OuterMessage.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'protocolVersion',
        fieldType: $pb.PbFieldType.QU3, defaultOrMaker: 1)
    ..aE<OuterMessage_Status>(2, _omitFieldNames ? '' : 'status',
        fieldType: $pb.PbFieldType.QE, enumValues: OuterMessage_Status.values)
    ..aOM<PairingRequest>(10, _omitFieldNames ? '' : 'pairingRequest',
        subBuilder: PairingRequest.$_createMessage)
    ..aOM<PairingRequestAck>(11, _omitFieldNames ? '' : 'pairingRequestAck',
        subBuilder: PairingRequestAck.$_createMessage)
    ..aOM<Options>(20, _omitFieldNames ? '' : 'options',
        subBuilder: Options.$_createMessage)
    ..aOM<Configuration>(30, _omitFieldNames ? '' : 'configuration',
        subBuilder: Configuration.$_createMessage)
    ..aOM<ConfigurationAck>(31, _omitFieldNames ? '' : 'configurationAck',
        subBuilder: ConfigurationAck.$_createMessage)
    ..aOM<Secret>(40, _omitFieldNames ? '' : 'secret',
        subBuilder: Secret.$_createMessage)
    ..aOM<SecretAck>(41, _omitFieldNames ? '' : 'secretAck',
        subBuilder: SecretAck.$_createMessage);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OuterMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OuterMessage copyWith(void Function(OuterMessage) updates) =>
      super.copyWith((message) => updates(message as OuterMessage))
          as OuterMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OuterMessage() / OuterMessage.new instead')
  static OuterMessage create() => OuterMessage._();
  static $pb.GeneratedMessage $_createMessage() => OuterMessage._();
  @$core.override
  OuterMessage createEmptyInstance() => OuterMessage._();
  @$core.pragma('dart2js:noInline')
  static OuterMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OuterMessage>(
          OuterMessage.$_createMessage);
  static OuterMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get protocolVersion => $_getI(0, 1);
  @$pb.TagNumber(1)
  set protocolVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProtocolVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearProtocolVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  OuterMessage_Status get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(OuterMessage_Status value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(10)
  PairingRequest get pairingRequest => $_getN(2);
  @$pb.TagNumber(10)
  set pairingRequest(PairingRequest value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPairingRequest() => $_has(2);
  @$pb.TagNumber(10)
  void clearPairingRequest() => $_clearField(10);
  @$pb.TagNumber(10)
  PairingRequest ensurePairingRequest() => $_ensure(2);

  @$pb.TagNumber(11)
  PairingRequestAck get pairingRequestAck => $_getN(3);
  @$pb.TagNumber(11)
  set pairingRequestAck(PairingRequestAck value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasPairingRequestAck() => $_has(3);
  @$pb.TagNumber(11)
  void clearPairingRequestAck() => $_clearField(11);
  @$pb.TagNumber(11)
  PairingRequestAck ensurePairingRequestAck() => $_ensure(3);

  @$pb.TagNumber(20)
  Options get options => $_getN(4);
  @$pb.TagNumber(20)
  set options(Options value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasOptions() => $_has(4);
  @$pb.TagNumber(20)
  void clearOptions() => $_clearField(20);
  @$pb.TagNumber(20)
  Options ensureOptions() => $_ensure(4);

  @$pb.TagNumber(30)
  Configuration get configuration => $_getN(5);
  @$pb.TagNumber(30)
  set configuration(Configuration value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasConfiguration() => $_has(5);
  @$pb.TagNumber(30)
  void clearConfiguration() => $_clearField(30);
  @$pb.TagNumber(30)
  Configuration ensureConfiguration() => $_ensure(5);

  @$pb.TagNumber(31)
  ConfigurationAck get configurationAck => $_getN(6);
  @$pb.TagNumber(31)
  set configurationAck(ConfigurationAck value) => $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasConfigurationAck() => $_has(6);
  @$pb.TagNumber(31)
  void clearConfigurationAck() => $_clearField(31);
  @$pb.TagNumber(31)
  ConfigurationAck ensureConfigurationAck() => $_ensure(6);

  @$pb.TagNumber(40)
  Secret get secret => $_getN(7);
  @$pb.TagNumber(40)
  set secret(Secret value) => $_setField(40, value);
  @$pb.TagNumber(40)
  $core.bool hasSecret() => $_has(7);
  @$pb.TagNumber(40)
  void clearSecret() => $_clearField(40);
  @$pb.TagNumber(40)
  Secret ensureSecret() => $_ensure(7);

  @$pb.TagNumber(41)
  SecretAck get secretAck => $_getN(8);
  @$pb.TagNumber(41)
  set secretAck(SecretAck value) => $_setField(41, value);
  @$pb.TagNumber(41)
  $core.bool hasSecretAck() => $_has(8);
  @$pb.TagNumber(41)
  void clearSecretAck() => $_clearField(41);
  @$pb.TagNumber(41)
  SecretAck ensureSecretAck() => $_ensure(8);
}

class PairingRequest extends $pb.GeneratedMessage {
  factory PairingRequest({
    $core.String? serviceName,
    $core.String? clientName,
  }) {
    final result = PairingRequest._();
    if (serviceName != null) result.serviceName = serviceName;
    if (clientName != null) result.clientName = clientName;
    return result;
  }

  PairingRequest._();

  factory PairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingRequest()..mergeFromBuffer(data, registry);
  factory PairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: PairingRequest.$_createMessage)
    ..aQS(1, _omitFieldNames ? '' : 'serviceName')
    ..aOS(2, _omitFieldNames ? '' : 'clientName');

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRequest copyWith(void Function(PairingRequest) updates) =>
      super.copyWith((message) => updates(message as PairingRequest))
          as PairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingRequest() / PairingRequest.new instead')
  static PairingRequest create() => PairingRequest._();
  static $pb.GeneratedMessage $_createMessage() => PairingRequest._();
  @$core.override
  PairingRequest createEmptyInstance() => PairingRequest._();
  @$core.pragma('dart2js:noInline')
  static PairingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingRequest>(
          PairingRequest.$_createMessage);
  static PairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serviceName => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceName() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get clientName => $_getSZ(1);
  @$pb.TagNumber(2)
  set clientName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClientName() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientName() => $_clearField(2);
}

class PairingRequestAck extends $pb.GeneratedMessage {
  factory PairingRequestAck({
    $core.String? serverName,
  }) {
    final result = PairingRequestAck._();
    if (serverName != null) result.serverName = serverName;
    return result;
  }

  PairingRequestAck._();

  factory PairingRequestAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingRequestAck()..mergeFromBuffer(data, registry);
  factory PairingRequestAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PairingRequestAck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PairingRequestAck',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: PairingRequestAck.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'serverName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRequestAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PairingRequestAck copyWith(void Function(PairingRequestAck) updates) =>
      super.copyWith((message) => updates(message as PairingRequestAck))
          as PairingRequestAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PairingRequestAck() / PairingRequestAck.new instead')
  static PairingRequestAck create() => PairingRequestAck._();
  static $pb.GeneratedMessage $_createMessage() => PairingRequestAck._();
  @$core.override
  PairingRequestAck createEmptyInstance() => PairingRequestAck._();
  @$core.pragma('dart2js:noInline')
  static PairingRequestAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PairingRequestAck>(
          PairingRequestAck.$_createMessage);
  static PairingRequestAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverName => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerName() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerName() => $_clearField(1);
}

class Options_Encoding extends $pb.GeneratedMessage {
  factory Options_Encoding({
    Options_Encoding_EncodingType? type,
    $core.int? symbolLength,
  }) {
    final result = Options_Encoding._();
    if (type != null) result.type = type;
    if (symbolLength != null) result.symbolLength = symbolLength;
    return result;
  }

  Options_Encoding._();

  factory Options_Encoding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Options_Encoding()..mergeFromBuffer(data, registry);
  factory Options_Encoding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Options_Encoding()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Options.Encoding',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: Options_Encoding.$_createMessage)
    ..aE<Options_Encoding_EncodingType>(1, _omitFieldNames ? '' : 'type',
        fieldType: $pb.PbFieldType.QE,
        enumValues: Options_Encoding_EncodingType.values)
    ..aI(2, _omitFieldNames ? '' : 'symbolLength',
        fieldType: $pb.PbFieldType.QU3);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Options_Encoding clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Options_Encoding copyWith(void Function(Options_Encoding) updates) =>
      super.copyWith((message) => updates(message as Options_Encoding))
          as Options_Encoding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Options_Encoding() / Options_Encoding.new instead')
  static Options_Encoding create() => Options_Encoding._();
  static $pb.GeneratedMessage $_createMessage() => Options_Encoding._();
  @$core.override
  Options_Encoding createEmptyInstance() => Options_Encoding._();
  @$core.pragma('dart2js:noInline')
  static Options_Encoding getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Options_Encoding>(
          Options_Encoding.$_createMessage);
  static Options_Encoding? _defaultInstance;

  @$pb.TagNumber(1)
  Options_Encoding_EncodingType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(Options_Encoding_EncodingType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get symbolLength => $_getIZ(1);
  @$pb.TagNumber(2)
  set symbolLength($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSymbolLength() => $_has(1);
  @$pb.TagNumber(2)
  void clearSymbolLength() => $_clearField(2);
}

class Options extends $pb.GeneratedMessage {
  factory Options({
    $core.Iterable<Options_Encoding>? inputEncodings,
    $core.Iterable<Options_Encoding>? outputEncodings,
    Options_RoleType? preferredRole,
  }) {
    final result = Options._();
    if (inputEncodings != null) result.inputEncodings.addAll(inputEncodings);
    if (outputEncodings != null) result.outputEncodings.addAll(outputEncodings);
    if (preferredRole != null) result.preferredRole = preferredRole;
    return result;
  }

  Options._();

  factory Options.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Options()..mergeFromBuffer(data, registry);
  factory Options.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Options()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Options',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: Options.$_createMessage)
    ..pPM<Options_Encoding>(1, _omitFieldNames ? '' : 'inputEncodings',
        subBuilder: Options_Encoding.$_createMessage)
    ..pPM<Options_Encoding>(2, _omitFieldNames ? '' : 'outputEncodings',
        subBuilder: Options_Encoding.$_createMessage)
    ..aE<Options_RoleType>(3, _omitFieldNames ? '' : 'preferredRole',
        enumValues: Options_RoleType.values);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Options clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Options copyWith(void Function(Options) updates) =>
      super.copyWith((message) => updates(message as Options)) as Options;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Options() / Options.new instead')
  static Options create() => Options._();
  static $pb.GeneratedMessage $_createMessage() => Options._();
  @$core.override
  Options createEmptyInstance() => Options._();
  @$core.pragma('dart2js:noInline')
  static Options getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Options>(Options.$_createMessage);
  static Options? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Options_Encoding> get inputEncodings => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<Options_Encoding> get outputEncodings => $_getList(1);

  @$pb.TagNumber(3)
  Options_RoleType get preferredRole => $_getN(2);
  @$pb.TagNumber(3)
  set preferredRole(Options_RoleType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPreferredRole() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreferredRole() => $_clearField(3);
}

class Configuration extends $pb.GeneratedMessage {
  factory Configuration({
    Options_Encoding? encoding,
    Options_RoleType? clientRole,
  }) {
    final result = Configuration._();
    if (encoding != null) result.encoding = encoding;
    if (clientRole != null) result.clientRole = clientRole;
    return result;
  }

  Configuration._();

  factory Configuration.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Configuration()..mergeFromBuffer(data, registry);
  factory Configuration.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Configuration()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Configuration',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: Configuration.$_createMessage)
    ..aQM<Options_Encoding>(1, _omitFieldNames ? '' : 'encoding',
        subBuilder: Options_Encoding.$_createMessage)
    ..aE<Options_RoleType>(2, _omitFieldNames ? '' : 'clientRole',
        fieldType: $pb.PbFieldType.QE, enumValues: Options_RoleType.values);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Configuration clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Configuration copyWith(void Function(Configuration) updates) =>
      super.copyWith((message) => updates(message as Configuration))
          as Configuration;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Configuration() / Configuration.new instead')
  static Configuration create() => Configuration._();
  static $pb.GeneratedMessage $_createMessage() => Configuration._();
  @$core.override
  Configuration createEmptyInstance() => Configuration._();
  @$core.pragma('dart2js:noInline')
  static Configuration getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Configuration>(
          Configuration.$_createMessage);
  static Configuration? _defaultInstance;

  @$pb.TagNumber(1)
  Options_Encoding get encoding => $_getN(0);
  @$pb.TagNumber(1)
  set encoding(Options_Encoding value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEncoding() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncoding() => $_clearField(1);
  @$pb.TagNumber(1)
  Options_Encoding ensureEncoding() => $_ensure(0);

  @$pb.TagNumber(2)
  Options_RoleType get clientRole => $_getN(1);
  @$pb.TagNumber(2)
  set clientRole(Options_RoleType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasClientRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearClientRole() => $_clearField(2);
}

class ConfigurationAck extends $pb.GeneratedMessage {
  factory ConfigurationAck() => ConfigurationAck._();

  ConfigurationAck._();

  factory ConfigurationAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConfigurationAck()..mergeFromBuffer(data, registry);
  factory ConfigurationAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConfigurationAck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConfigurationAck',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: ConfigurationAck.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigurationAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConfigurationAck copyWith(void Function(ConfigurationAck) updates) =>
      super.copyWith((message) => updates(message as ConfigurationAck))
          as ConfigurationAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConfigurationAck() / ConfigurationAck.new instead')
  static ConfigurationAck create() => ConfigurationAck._();
  static $pb.GeneratedMessage $_createMessage() => ConfigurationAck._();
  @$core.override
  ConfigurationAck createEmptyInstance() => ConfigurationAck._();
  @$core.pragma('dart2js:noInline')
  static ConfigurationAck getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConfigurationAck>(
          ConfigurationAck.$_createMessage);
  static ConfigurationAck? _defaultInstance;
}

class Secret extends $pb.GeneratedMessage {
  factory Secret({
    $core.List<$core.int>? secret,
  }) {
    final result = Secret._();
    if (secret != null) result.secret = secret;
    return result;
  }

  Secret._();

  factory Secret.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Secret()..mergeFromBuffer(data, registry);
  factory Secret.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Secret()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Secret',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: Secret.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.QY);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Secret clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Secret copyWith(void Function(Secret) updates) =>
      super.copyWith((message) => updates(message as Secret)) as Secret;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Secret() / Secret.new instead')
  static Secret create() => Secret._();
  static $pb.GeneratedMessage $_createMessage() => Secret._();
  @$core.override
  Secret createEmptyInstance() => Secret._();
  @$core.pragma('dart2js:noInline')
  static Secret getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Secret>(Secret.$_createMessage);
  static Secret? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);
  @$pb.TagNumber(1)
  set secret($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => $_clearField(1);
}

class SecretAck extends $pb.GeneratedMessage {
  factory SecretAck({
    $core.List<$core.int>? secret,
  }) {
    final result = SecretAck._();
    if (secret != null) result.secret = secret;
    return result;
  }

  SecretAck._();

  factory SecretAck.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretAck()..mergeFromBuffer(data, registry);
  factory SecretAck.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SecretAck()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SecretAck',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'polo.wire.protobuf'),
      createEmptyInstance: SecretAck.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.QY);

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretAck clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SecretAck copyWith(void Function(SecretAck) updates) =>
      super.copyWith((message) => updates(message as SecretAck)) as SecretAck;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SecretAck() / SecretAck.new instead')
  static SecretAck create() => SecretAck._();
  static $pb.GeneratedMessage $_createMessage() => SecretAck._();
  @$core.override
  SecretAck createEmptyInstance() => SecretAck._();
  @$core.pragma('dart2js:noInline')
  static SecretAck getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SecretAck>(SecretAck.$_createMessage);
  static SecretAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);
  @$pb.TagNumber(1)
  set secret($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
