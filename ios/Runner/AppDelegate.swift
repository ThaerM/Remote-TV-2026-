import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private var bonjourDiscoveryBridge: BonjourDiscoveryBridge?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar: FlutterPluginRegistrar? = engineBridge.pluginRegistry.registrar(
      forPlugin: "BonjourDiscoveryBridge")
    if let registrar = registrar {
      bonjourDiscoveryBridge = BonjourDiscoveryBridge(messenger: registrar.messenger())
    }
  }
}
