// This is a generated file - do not edit.
//
// Generated from polo.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use outerMessageDescriptor instead')
const OuterMessage$json = {
  '1': 'OuterMessage',
  '2': [
    {
      '1': 'protocol_version',
      '3': 1,
      '4': 2,
      '5': 13,
      '7': '1',
      '10': 'protocolVersion'
    },
    {
      '1': 'status',
      '3': 2,
      '4': 2,
      '5': 14,
      '6': '.polo.wire.protobuf.OuterMessage.Status',
      '10': 'status'
    },
    {
      '1': 'pairing_request',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.PairingRequest',
      '10': 'pairingRequest'
    },
    {
      '1': 'pairing_request_ack',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.PairingRequestAck',
      '10': 'pairingRequestAck'
    },
    {
      '1': 'options',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.Options',
      '10': 'options'
    },
    {
      '1': 'configuration',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.Configuration',
      '10': 'configuration'
    },
    {
      '1': 'configuration_ack',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.ConfigurationAck',
      '10': 'configurationAck'
    },
    {
      '1': 'secret',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.Secret',
      '10': 'secret'
    },
    {
      '1': 'secret_ack',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.polo.wire.protobuf.SecretAck',
      '10': 'secretAck'
    },
  ],
  '4': [OuterMessage_Status$json],
};

@$core.Deprecated('Use outerMessageDescriptor instead')
const OuterMessage_Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'STATUS_OK', '2': 200},
    {'1': 'STATUS_ERROR', '2': 400},
    {'1': 'STATUS_BAD_CONFIGURATION', '2': 401},
    {'1': 'STATUS_BAD_SECRET', '2': 402},
  ],
};

/// Descriptor for `OuterMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outerMessageDescriptor = $convert.base64Decode(
    'CgxPdXRlck1lc3NhZ2USLAoQcHJvdG9jb2xfdmVyc2lvbhgBIAIoDToBMVIPcHJvdG9jb2xWZX'
    'JzaW9uEj8KBnN0YXR1cxgCIAIoDjInLnBvbG8ud2lyZS5wcm90b2J1Zi5PdXRlck1lc3NhZ2Uu'
    'U3RhdHVzUgZzdGF0dXMSSwoPcGFpcmluZ19yZXF1ZXN0GAogASgLMiIucG9sby53aXJlLnByb3'
    'RvYnVmLlBhaXJpbmdSZXF1ZXN0Ug5wYWlyaW5nUmVxdWVzdBJVChNwYWlyaW5nX3JlcXVlc3Rf'
    'YWNrGAsgASgLMiUucG9sby53aXJlLnByb3RvYnVmLlBhaXJpbmdSZXF1ZXN0QWNrUhFwYWlyaW'
    '5nUmVxdWVzdEFjaxI1CgdvcHRpb25zGBQgASgLMhsucG9sby53aXJlLnByb3RvYnVmLk9wdGlv'
    'bnNSB29wdGlvbnMSRwoNY29uZmlndXJhdGlvbhgeIAEoCzIhLnBvbG8ud2lyZS5wcm90b2J1Zi'
    '5Db25maWd1cmF0aW9uUg1jb25maWd1cmF0aW9uElEKEWNvbmZpZ3VyYXRpb25fYWNrGB8gASgL'
    'MiQucG9sby53aXJlLnByb3RvYnVmLkNvbmZpZ3VyYXRpb25BY2tSEGNvbmZpZ3VyYXRpb25BY2'
    'sSMgoGc2VjcmV0GCggASgLMhoucG9sby53aXJlLnByb3RvYnVmLlNlY3JldFIGc2VjcmV0EjwK'
    'CnNlY3JldF9hY2sYKSABKAsyHS5wb2xvLndpcmUucHJvdG9idWYuU2VjcmV0QWNrUglzZWNyZX'
    'RBY2siYgoGU3RhdHVzEg4KCVNUQVRVU19PSxDIARIRCgxTVEFUVVNfRVJST1IQkAMSHQoYU1RB'
    'VFVTX0JBRF9DT05GSUdVUkFUSU9OEJEDEhYKEVNUQVRVU19CQURfU0VDUkVUEJID');

@$core.Deprecated('Use pairingRequestDescriptor instead')
const PairingRequest$json = {
  '1': 'PairingRequest',
  '2': [
    {'1': 'service_name', '3': 1, '4': 2, '5': 9, '10': 'serviceName'},
    {'1': 'client_name', '3': 2, '4': 1, '5': 9, '10': 'clientName'},
  ],
};

/// Descriptor for `PairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRequestDescriptor = $convert.base64Decode(
    'Cg5QYWlyaW5nUmVxdWVzdBIhCgxzZXJ2aWNlX25hbWUYASACKAlSC3NlcnZpY2VOYW1lEh8KC2'
    'NsaWVudF9uYW1lGAIgASgJUgpjbGllbnROYW1l');

@$core.Deprecated('Use pairingRequestAckDescriptor instead')
const PairingRequestAck$json = {
  '1': 'PairingRequestAck',
  '2': [
    {'1': 'server_name', '3': 1, '4': 1, '5': 9, '10': 'serverName'},
  ],
};

/// Descriptor for `PairingRequestAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRequestAckDescriptor = $convert.base64Decode(
    'ChFQYWlyaW5nUmVxdWVzdEFjaxIfCgtzZXJ2ZXJfbmFtZRgBIAEoCVIKc2VydmVyTmFtZQ==');

@$core.Deprecated('Use optionsDescriptor instead')
const Options$json = {
  '1': 'Options',
  '2': [
    {
      '1': 'input_encodings',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.polo.wire.protobuf.Options.Encoding',
      '10': 'inputEncodings'
    },
    {
      '1': 'output_encodings',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.polo.wire.protobuf.Options.Encoding',
      '10': 'outputEncodings'
    },
    {
      '1': 'preferred_role',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.polo.wire.protobuf.Options.RoleType',
      '10': 'preferredRole'
    },
  ],
  '3': [Options_Encoding$json],
  '4': [Options_RoleType$json],
};

@$core.Deprecated('Use optionsDescriptor instead')
const Options_Encoding$json = {
  '1': 'Encoding',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 2,
      '5': 14,
      '6': '.polo.wire.protobuf.Options.Encoding.EncodingType',
      '10': 'type'
    },
    {'1': 'symbol_length', '3': 2, '4': 2, '5': 13, '10': 'symbolLength'},
  ],
  '4': [Options_Encoding_EncodingType$json],
};

@$core.Deprecated('Use optionsDescriptor instead')
const Options_Encoding_EncodingType$json = {
  '1': 'EncodingType',
  '2': [
    {'1': 'ENCODING_TYPE_UNKNOWN', '2': 0},
    {'1': 'ENCODING_TYPE_ALPHANUMERIC', '2': 1},
    {'1': 'ENCODING_TYPE_NUMERIC', '2': 2},
    {'1': 'ENCODING_TYPE_HEXADECIMAL', '2': 3},
    {'1': 'ENCODING_TYPE_QRCODE', '2': 4},
  ],
};

@$core.Deprecated('Use optionsDescriptor instead')
const Options_RoleType$json = {
  '1': 'RoleType',
  '2': [
    {'1': 'ROLE_TYPE_UNKNOWN', '2': 0},
    {'1': 'ROLE_TYPE_INPUT', '2': 1},
    {'1': 'ROLE_TYPE_OUTPUT', '2': 2},
  ],
};

/// Descriptor for `Options`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List optionsDescriptor = $convert.base64Decode(
    'CgdPcHRpb25zEk0KD2lucHV0X2VuY29kaW5ncxgBIAMoCzIkLnBvbG8ud2lyZS5wcm90b2J1Zi'
    '5PcHRpb25zLkVuY29kaW5nUg5pbnB1dEVuY29kaW5ncxJPChBvdXRwdXRfZW5jb2RpbmdzGAIg'
    'AygLMiQucG9sby53aXJlLnByb3RvYnVmLk9wdGlvbnMuRW5jb2RpbmdSD291dHB1dEVuY29kaW'
    '5ncxJLCg5wcmVmZXJyZWRfcm9sZRgDIAEoDjIkLnBvbG8ud2lyZS5wcm90b2J1Zi5PcHRpb25z'
    'LlJvbGVUeXBlUg1wcmVmZXJyZWRSb2xlGpYCCghFbmNvZGluZxJFCgR0eXBlGAEgAigOMjEucG'
    '9sby53aXJlLnByb3RvYnVmLk9wdGlvbnMuRW5jb2RpbmcuRW5jb2RpbmdUeXBlUgR0eXBlEiMK'
    'DXN5bWJvbF9sZW5ndGgYAiACKA1SDHN5bWJvbExlbmd0aCKdAQoMRW5jb2RpbmdUeXBlEhkKFU'
    'VOQ09ESU5HX1RZUEVfVU5LTk9XThAAEh4KGkVOQ09ESU5HX1RZUEVfQUxQSEFOVU1FUklDEAES'
    'GQoVRU5DT0RJTkdfVFlQRV9OVU1FUklDEAISHQoZRU5DT0RJTkdfVFlQRV9IRVhBREVDSU1BTB'
    'ADEhgKFEVOQ09ESU5HX1RZUEVfUVJDT0RFEAQiTAoIUm9sZVR5cGUSFQoRUk9MRV9UWVBFX1VO'
    'S05PV04QABITCg9ST0xFX1RZUEVfSU5QVVQQARIUChBST0xFX1RZUEVfT1VUUFVUEAI=');

@$core.Deprecated('Use configurationDescriptor instead')
const Configuration$json = {
  '1': 'Configuration',
  '2': [
    {
      '1': 'encoding',
      '3': 1,
      '4': 2,
      '5': 11,
      '6': '.polo.wire.protobuf.Options.Encoding',
      '10': 'encoding'
    },
    {
      '1': 'client_role',
      '3': 2,
      '4': 2,
      '5': 14,
      '6': '.polo.wire.protobuf.Options.RoleType',
      '10': 'clientRole'
    },
  ],
};

/// Descriptor for `Configuration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configurationDescriptor = $convert.base64Decode(
    'Cg1Db25maWd1cmF0aW9uEkAKCGVuY29kaW5nGAEgAigLMiQucG9sby53aXJlLnByb3RvYnVmLk'
    '9wdGlvbnMuRW5jb2RpbmdSCGVuY29kaW5nEkUKC2NsaWVudF9yb2xlGAIgAigOMiQucG9sby53'
    'aXJlLnByb3RvYnVmLk9wdGlvbnMuUm9sZVR5cGVSCmNsaWVudFJvbGU=');

@$core.Deprecated('Use configurationAckDescriptor instead')
const ConfigurationAck$json = {
  '1': 'ConfigurationAck',
};

/// Descriptor for `ConfigurationAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List configurationAckDescriptor =
    $convert.base64Decode('ChBDb25maWd1cmF0aW9uQWNr');

@$core.Deprecated('Use secretDescriptor instead')
const Secret$json = {
  '1': 'Secret',
  '2': [
    {'1': 'secret', '3': 1, '4': 2, '5': 12, '10': 'secret'},
  ],
};

/// Descriptor for `Secret`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List secretDescriptor =
    $convert.base64Decode('CgZTZWNyZXQSFgoGc2VjcmV0GAEgAigMUgZzZWNyZXQ=');

@$core.Deprecated('Use secretAckDescriptor instead')
const SecretAck$json = {
  '1': 'SecretAck',
  '2': [
    {'1': 'secret', '3': 1, '4': 2, '5': 12, '10': 'secret'},
  ],
};

/// Descriptor for `SecretAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List secretAckDescriptor =
    $convert.base64Decode('CglTZWNyZXRBY2sSFgoGc2VjcmV0GAEgAigMUgZzZWNyZXQ=');
