import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Bounded plain-HTTP GET returning the body, or null on any failure.
typedef HttpTextGetter = Future<String?> Function(Uri uri);

Future<String?> ioHttpGetText(
  Uri uri, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    return await response.transform(utf8.decoder).join().timeout(timeout);
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}

class UpnpService {
  const UpnpService({required this.serviceType, required this.controlUrl});

  final String serviceType;

  /// Absolute, resolved against the description's location.
  final Uri controlUrl;
}

/// The parts of a UPnP device description (the XML at an SSDP `LOCATION`)
/// the app uses.
class UpnpDeviceDescription {
  const UpnpDeviceDescription({
    required this.friendlyName,
    this.udn,
    this.manufacturer,
    this.modelName,
    this.services = const [],
  });

  final String friendlyName;
  final String? udn;
  final String? manufacturer;
  final String? modelName;
  final List<UpnpService> services;

  UpnpService? service(String typePrefix) =>
      services.where((s) => s.serviceType.startsWith(typePrefix)).firstOrNull;

  static UpnpDeviceDescription? parse(String xml, Uri location) {
    final name = _tag(xml, 'friendlyName');
    if (name == null || name.isEmpty) return null;
    final base = _tag(xml, 'URLBase');
    final baseUri = base == null ? location : (Uri.tryParse(base) ?? location);
    final services = <UpnpService>[];
    for (final match in RegExp(
      r'<service>([\s\S]*?)</service>',
    ).allMatches(xml)) {
      final block = match.group(1)!;
      final type = _tag(block, 'serviceType');
      final control = _tag(block, 'controlURL');
      if (type == null || control == null) continue;
      services.add(
        UpnpService(serviceType: type, controlUrl: baseUri.resolve(control)),
      );
    }
    return UpnpDeviceDescription(
      friendlyName: name,
      udn: _tag(xml, 'UDN'),
      manufacturer: _tag(xml, 'manufacturer'),
      modelName: _tag(xml, 'modelName'),
      services: services,
    );
  }

  static Future<UpnpDeviceDescription?> fetch(
    Uri location, {
    HttpTextGetter get = ioHttpGetText,
  }) async {
    final xml = await get(location);
    return xml == null ? null : parse(xml, location);
  }
}

String? _tag(String xml, String name) {
  final match = RegExp(
    '<(?:[A-Za-z0-9]+:)?$name>([^<]*)</(?:[A-Za-z0-9]+:)?$name>',
  ).firstMatch(xml);
  return match == null ? null : decodeXmlText(match.group(1)!.trim());
}

String decodeXmlText(String value) => value
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

String encodeXmlText(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
