import 'tv_device.dart';
import 'tv_platform.dart';

/// Groups the separate protocol endpoints a single physical TV was
/// discovered under (e.g. its Android TV Remote service and its Google
/// Cast receiver) into one presentation-level entity, so Discovery shows
/// one card for the TV instead of one per protocol.
///
/// This is a grouping layer above discovery results only.
/// [AndroidTvProvider], [GoogleCastProvider] and every other
/// [TvProvider] stay completely separate - nothing here merges a wire
/// protocol or a connection - see docs/architecture/provider-system.md.
/// `TvSessionController.connect` still takes a single [TvDevice] exactly
/// as before; a caller that wants "the physical TV" just passes
/// [primary].
class PhysicalTvDevice {
  const PhysicalTvDevice({required this.endpoints})
    : assert(endpoints.length > 0, 'A physical device needs an endpoint.');

  /// Every discovered endpoint that resolved to this device, in the order
  /// discovery produced them. Never empty.
  final List<TvDevice> endpoints;

  /// True when two or more endpoints (different protocols) were merged
  /// into this one card - the case the UI shows capability badges for.
  bool get isGrouped => endpoints.length > 1;

  /// The endpoint to lead with: a full remote-control endpoint if the TV
  /// has one (Android TV, Roku, LG, Samsung - anything that isn't
  /// [TvPlatform.isCastOnly]), otherwise whatever was found. Connecting
  /// to a grouped device always starts here, so the user is never asked
  /// to choose a protocol for a normal Google TV.
  TvDevice get primary {
    for (final endpoint in endpoints) {
      if (!endpoint.platform.isCastOnly) return endpoint;
    }
    return endpoints.first;
  }

  /// The remote-control endpoint, if this physical TV has one.
  TvDevice? get remoteEndpoint {
    for (final endpoint in endpoints) {
      if (!endpoint.platform.isCastOnly) return endpoint;
    }
    return null;
  }

  /// The cast-target endpoint, if this physical TV has one.
  TvDevice? get castEndpoint {
    for (final endpoint in endpoints) {
      if (endpoint.platform.isCastOnly) return endpoint;
    }
    return null;
  }

  bool get hasRemote => remoteEndpoint != null;
  bool get hasCast => castEndpoint != null;

  /// True if any endpoint is a [TvPlatform.fake] demo device - the UI
  /// must still label those clearly, grouped or not.
  bool get isDevelopmentFake => endpoints.any((e) => e.isDevelopmentFake);

  String get displayName => primary.name;

  /// A stable-enough identity for widget keys and list diffing - derived
  /// from the endpoints actually in this group, not invented.
  String get id => endpoints.map((e) => e.id).join('+');

  /// Groups [devices] by physical TV.
  ///
  /// The only evidence trusted to merge two endpoints is that they
  /// resolved to the **same host** (the IP or hostname discovery
  /// actually connected to - see `ServiceDiscoveryResult.host`) - never
  /// the display name alone, which real TVs and unrelated Chromecasts
  /// frequently share ("Living Room TV"). A device with no known host
  /// (manually-entered-but-not-yet-resolved, or a demo device) never
  /// groups with anything.
  ///
  /// Deterministic and order-preserving: the same input list always
  /// produces the same grouping in the same order, so a rescan can't
  /// flicker a card from grouped to split or back.
  static List<PhysicalTvDevice> group(List<TvDevice> devices) {
    final byHost = <String, List<TvDevice>>{};
    for (final device in devices) {
      final host = device.host;
      if (host == null || host.isEmpty) continue;
      byHost.putIfAbsent(host.toLowerCase(), () => []).add(device);
    }

    final result = <PhysicalTvDevice>[];
    final emittedHosts = <String>{};
    for (final device in devices) {
      final host = device.host?.toLowerCase();
      if (host == null || host.isEmpty) {
        result.add(PhysicalTvDevice(endpoints: [device]));
        continue;
      }
      if (!emittedHosts.add(host)) {
        continue; // this host's group already emitted
      }
      result.add(PhysicalTvDevice(endpoints: List.unmodifiable(byHost[host]!)));
    }
    return result;
  }
}
