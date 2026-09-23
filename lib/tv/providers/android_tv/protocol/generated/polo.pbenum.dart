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

class OuterMessage_Status extends $pb.ProtobufEnum {
  static const OuterMessage_Status STATUS_OK =
      OuterMessage_Status._(200, _omitEnumNames ? '' : 'STATUS_OK');
  static const OuterMessage_Status STATUS_ERROR =
      OuterMessage_Status._(400, _omitEnumNames ? '' : 'STATUS_ERROR');
  static const OuterMessage_Status STATUS_BAD_CONFIGURATION =
      OuterMessage_Status._(
          401, _omitEnumNames ? '' : 'STATUS_BAD_CONFIGURATION');
  static const OuterMessage_Status STATUS_BAD_SECRET =
      OuterMessage_Status._(402, _omitEnumNames ? '' : 'STATUS_BAD_SECRET');

  static const $core.List<OuterMessage_Status> values = <OuterMessage_Status>[
    STATUS_OK,
    STATUS_ERROR,
    STATUS_BAD_CONFIGURATION,
    STATUS_BAD_SECRET,
  ];

  static final $core.Map<$core.int, OuterMessage_Status> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static OuterMessage_Status? valueOf($core.int value) => _byValue[value];

  const OuterMessage_Status._(super.value, super.name);
}

class Options_RoleType extends $pb.ProtobufEnum {
  static const Options_RoleType ROLE_TYPE_UNKNOWN =
      Options_RoleType._(0, _omitEnumNames ? '' : 'ROLE_TYPE_UNKNOWN');
  static const Options_RoleType ROLE_TYPE_INPUT =
      Options_RoleType._(1, _omitEnumNames ? '' : 'ROLE_TYPE_INPUT');
  static const Options_RoleType ROLE_TYPE_OUTPUT =
      Options_RoleType._(2, _omitEnumNames ? '' : 'ROLE_TYPE_OUTPUT');

  static const $core.List<Options_RoleType> values = <Options_RoleType>[
    ROLE_TYPE_UNKNOWN,
    ROLE_TYPE_INPUT,
    ROLE_TYPE_OUTPUT,
  ];

  static final $core.List<Options_RoleType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Options_RoleType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Options_RoleType._(super.value, super.name);
}

class Options_Encoding_EncodingType extends $pb.ProtobufEnum {
  static const Options_Encoding_EncodingType ENCODING_TYPE_UNKNOWN =
      Options_Encoding_EncodingType._(
          0, _omitEnumNames ? '' : 'ENCODING_TYPE_UNKNOWN');
  static const Options_Encoding_EncodingType ENCODING_TYPE_ALPHANUMERIC =
      Options_Encoding_EncodingType._(
          1, _omitEnumNames ? '' : 'ENCODING_TYPE_ALPHANUMERIC');
  static const Options_Encoding_EncodingType ENCODING_TYPE_NUMERIC =
      Options_Encoding_EncodingType._(
          2, _omitEnumNames ? '' : 'ENCODING_TYPE_NUMERIC');
  static const Options_Encoding_EncodingType ENCODING_TYPE_HEXADECIMAL =
      Options_Encoding_EncodingType._(
          3, _omitEnumNames ? '' : 'ENCODING_TYPE_HEXADECIMAL');
  static const Options_Encoding_EncodingType ENCODING_TYPE_QRCODE =
      Options_Encoding_EncodingType._(
          4, _omitEnumNames ? '' : 'ENCODING_TYPE_QRCODE');

  static const $core.List<Options_Encoding_EncodingType> values =
      <Options_Encoding_EncodingType>[
    ENCODING_TYPE_UNKNOWN,
    ENCODING_TYPE_ALPHANUMERIC,
    ENCODING_TYPE_NUMERIC,
    ENCODING_TYPE_HEXADECIMAL,
    ENCODING_TYPE_QRCODE,
  ];

  static final $core.List<Options_Encoding_EncodingType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static Options_Encoding_EncodingType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Options_Encoding_EncodingType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
