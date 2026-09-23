import Flutter
import Foundation
import Network

/// Native Bonjour browse for Android TV Remote services, bridged to Dart's
/// `NativeBonjourAndroidTvDiscovery` over a MethodChannel.
///
/// Exists because iOS restricts raw multicast (UDP 5353) sockets in
/// third-party apps, which is what `package:multicast_dns` needs; the system
/// Bonjour stack only requires `NSLocalNetworkUsageDescription` and the
/// service listed in `NSBonjourServices`. `NWBrowser` browses (and reports
/// local-network-privacy denial precisely); `NetService` resolves host/port
/// without opening a connection to the TV.
final class AndroidTvBonjourDiscovery: NSObject {
  static let channelName = "remote_tv_2026/android_tv_bonjour"

  private let channel: FlutterMethodChannel
  private var activeScan: BonjourScan?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: AndroidTvBonjourDiscovery.channelName, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "browse" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: Any],
          let serviceType = args["serviceType"] as? String,
          let timeoutMs = args["timeoutMs"] as? Int,
          timeoutMs > 0 else {
      result(FlutterError(code: "bad_arguments", message: "browse needs serviceType and a positive timeoutMs", details: nil))
      return
    }

    // A newer scan supersedes an older one; the older call still gets
    // whatever it had found so far, so no Dart future is left pending.
    activeScan?.finish()
    let scan = BonjourScan(serviceType: serviceType, timeout: TimeInterval(timeoutMs) / 1000.0)
    activeScan = scan
    scan.start { [weak self, weak scan] payload in
      if let self = self, let scan = scan, self.activeScan === scan {
        self.activeScan = nil
      }
      result(payload)
    }
  }
}

/// One bounded browse+resolve pass. Everything runs on the main queue, so
/// the `NetService` instances resolve on the main run loop and no state is
/// shared across threads.
private final class BonjourScan: NSObject, NetServiceDelegate {
  // dns_sd.h error codes surfaced through NWError.dns.
  private static let policyDenied: Int32 = -65570
  private static let noAuth: Int32 = -65555

  private let serviceType: String
  private let timeout: TimeInterval
  private var browser: NWBrowser?
  private var deadline: DispatchWorkItem?
  private var completion: (([String: Any]) -> Void)?

  private var seenNames = Set<String>()
  private var resolving: [String: NetService] = [:]
  private var resolved: [String: [String: Any]] = [:]
  private var unresolved = Set<String>()
  private var failure: String?
  private var detail: String?

  init(serviceType: String, timeout: TimeInterval) {
    self.serviceType = serviceType
    self.timeout = timeout
    super.init()
  }

  func start(completion: @escaping ([String: Any]) -> Void) {
    self.completion = completion

    let parameters = NWParameters()
    parameters.includePeerToPeer = false
    let browser = NWBrowser(for: .bonjour(type: serviceType, domain: "local."), using: parameters)
    self.browser = browser
    browser.stateUpdateHandler = { [weak self] state in
      self?.handle(state: state)
    }
    browser.browseResultsChangedHandler = { [weak self] results, _ in
      self?.handle(results: results)
    }
    browser.start(queue: .main)

    let work = DispatchWorkItem { [weak self] in
      self?.finish()
    }
    deadline = work
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
  }

  private func handle(state: NWBrowser.State) {
    switch state {
    case .failed(let error):
      record(error)
      finish()
    case .waiting(let error):
      record(error)
      // Denied/misconfigured never recovers within one scan - stop early.
      if failure == "permission_denied_or_restricted" || failure == "bonjour_service_missing" {
        finish()
      }
    default:
      break
    }
  }

  private func record(_ error: NWError) {
    detail = "\(error)"
    if case let .dns(code) = error {
      switch code {
      case BonjourScan.policyDenied:
        failure = "permission_denied_or_restricted"
      case BonjourScan.noAuth:
        failure = "bonjour_service_missing"
      default:
        failure = "browse_failed"
      }
    } else {
      failure = "browse_failed"
    }
  }

  private func handle(results: Set<NWBrowser.Result>) {
    guard completion != nil else { return }
    for result in results {
      guard case let .service(name, type, domain, _) = result.endpoint,
            !seenNames.contains(name) else { continue }
      seenNames.insert(name)
      let service = NetService(domain: domain, type: type, name: name)
      service.delegate = self
      resolving[name] = service
      service.resolve(withTimeout: min(timeout, 3.0))
    }
  }

  func netServiceDidResolveAddress(_ sender: NetService) {
    guard completion != nil, resolving[sender.name] != nil else { return }
    var entry: [String: Any] = ["name": sender.name, "port": sender.port]
    if let host = sender.hostName {
      entry["host"] = host
    }
    if let ipv4 = BonjourScan.firstIPv4(sender.addresses) {
      entry["ipv4"] = ipv4
    }
    // Called again as more addresses arrive; keep the richest answer.
    if resolved[sender.name]?["ipv4"] == nil || entry["ipv4"] != nil {
      resolved[sender.name] = entry
    }
  }

  func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    guard completion != nil, resolving.removeValue(forKey: sender.name) != nil else { return }
    sender.stop()
    sender.delegate = nil
    if resolved[sender.name] == nil {
      unresolved.insert(sender.name)
    }
  }

  func finish() {
    guard let completion = completion else { return }
    self.completion = nil

    deadline?.cancel()
    deadline = nil
    browser?.stateUpdateHandler = nil
    browser?.browseResultsChangedHandler = nil
    browser?.cancel()
    browser = nil

    for (name, service) in resolving {
      service.stop()
      service.delegate = nil
      if resolved[name] == nil {
        unresolved.insert(name)
      }
    }
    resolving.removeAll()

    var payload: [String: Any] = [
      "services": Array(resolved.values),
      "unresolved": Array(unresolved),
      "browsed": seenNames.count,
    ]
    if let failure = failure {
      payload["failure"] = failure
    }
    if let detail = detail {
      payload["detail"] = detail
    }
    completion(payload)
  }

  private static func firstIPv4(_ addresses: [Data]?) -> String? {
    guard let addresses = addresses else { return nil }
    for data in addresses where data.count >= MemoryLayout<sockaddr_in>.size {
      let text: String? = data.withUnsafeBytes { raw -> String? in
        let socketAddress = raw.loadUnaligned(as: sockaddr_in.self)
        guard socketAddress.sin_family == sa_family_t(AF_INET) else { return nil }
        var address = socketAddress.sin_addr
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &address, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
          return nil
        }
        return String(cString: buffer)
      }
      if let text = text {
        return text
      }
    }
    return nil
  }
}
