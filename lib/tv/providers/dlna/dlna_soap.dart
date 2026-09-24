import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/network/upnp_description.dart';
import '../../domain/tv_domain.dart';

abstract final class DlnaConstants {
  static const String ssdpSearchTarget =
      'urn:schemas-upnp-org:device:MediaRenderer:1';
  static const String avTransport =
      'urn:schemas-upnp-org:service:AVTransport:1';
  static const String renderingControl =
      'urn:schemas-upnp-org:service:RenderingControl:1';
}

class SoapResponse {
  const SoapResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

/// POSTs one SOAP action; injectable for tests.
typedef SoapPoster = Future<SoapResponse> Function(
  Uri controlUrl,
  String soapAction,
  String body,
);

Future<SoapResponse> ioSoapPost(Uri url, String soapAction, String body) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client
        .postUrl(url)
        .timeout(const Duration(seconds: 3));
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'text/xml; charset="utf-8"')
      ..set('SOAPAction', '"$soapAction"');
    request.add(utf8.encode(body));
    final response = await request.close().timeout(const Duration(seconds: 5));
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 5));
    return SoapResponse(response.statusCode, text);
  } finally {
    client.close(force: true);
  }
}

/// One UPnP service's SOAP actions, with faults mapped to [TvException]s.
class UpnpSoapClient {
  UpnpSoapClient(this.serviceType, this.controlUrl, this._post);

  final String serviceType;
  final Uri controlUrl;
  final SoapPoster _post;

  /// Calls [action] with [arguments] (in order - UPnP requires the
  /// declared argument order) and returns the response's out-arguments.
  Future<Map<String, String>> call(
    String action, [
    Map<String, String> arguments = const {},
  ]) async {
    final args = arguments.entries
        .map((e) => '<${e.key}>${encodeXmlText(e.value)}</${e.key}>')
        .join();
    final body =
        '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body><u:$action xmlns:u="$serviceType">$args</u:$action></s:Body>'
        '</s:Envelope>';

    final SoapResponse response;
    try {
      response = await _post(controlUrl, '$serviceType#$action', body);
    } on TimeoutException {
      throw DeviceNotReachableException('The TV did not answer $action.');
    } on SocketException catch (error) {
      throw DeviceNotReachableException(
        'Could not reach the TV (${error.osError?.message ?? error.message}).',
      );
    } on HttpException catch (error) {
      throw DeviceNotReachableException(
        'Could not reach the TV (${error.message}).',
      );
    }

    if (response.statusCode != 200) {
      final code = RegExp(r'<(?:\w+:)?errorCode>(\d+)</')
          .firstMatch(response.body)
          ?.group(1);
      throw TvMediaSessionException(_describeFault(action, code));
    }
    final out = <String, String>{};
    final responseBody = RegExp(
      '<(?:\\w+:)?${action}Response[^>]*>([\\s\\S]*?)</(?:\\w+:)?${action}Response>',
    ).firstMatch(response.body)?.group(1);
    if (responseBody != null) {
      for (final match in RegExp(
        r'<(\w+)>([^<]*)</\1>',
      ).allMatches(responseBody)) {
        out[match.group(1)!] = decodeXmlText(match.group(2)!);
      }
    }
    return out;
  }

  static String _describeFault(String action, String? code) => switch (code) {
    '714' ||
    '715' ||
    '716' => 'The TV cannot play this media (unsupported format or link).',
    '701' => 'The TV refused $action right now (nothing is playing).',
    '710' => 'The TV cannot seek in this media.',
    null => 'The TV rejected $action.',
    _ => 'The TV rejected $action (UPnP error $code).',
  };
}

/// DIDL-Lite metadata most renderers want alongside the URI (some refuse
/// to play without a `protocolInfo` matching the MIME type).
String didlLiteFor(TvMediaItem item) {
  final cls = item.contentType.startsWith('audio/')
      ? 'object.item.audioItem.musicTrack'
      : item.contentType.startsWith('image/')
      ? 'object.item.imageItem.photo'
      : 'object.item.videoItem';
  final title = encodeXmlText(item.title ?? 'Remote TV 2026');
  final url = encodeXmlText(item.url.toString());
  return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" '
      'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
      '<item id="0" parentID="-1" restricted="1">'
      '<dc:title>$title</dc:title><upnp:class>$cls</upnp:class>'
      '<res protocolInfo="http-get:*:${item.contentType}:*">$url</res>'
      '</item></DIDL-Lite>';
}

/// `H:MM:SS` <-> [Duration], as AVTransport uses for RelTime/Seek.
Duration? parseUpnpTime(String? value) {
  if (value == null || value.isEmpty || value == 'NOT_IMPLEMENTED') return null;
  final parts = value.split(':');
  if (parts.length != 3) return null;
  final hours = int.tryParse(parts[0]);
  final minutes = int.tryParse(parts[1]);
  final seconds = double.tryParse(parts[2]);
  if (hours == null || minutes == null || seconds == null) return null;
  return Duration(
    hours: hours,
    minutes: minutes,
    milliseconds: (seconds * 1000).round(),
  );
}

String formatUpnpTime(Duration value) {
  final d = value.isNegative ? Duration.zero : value;
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}
