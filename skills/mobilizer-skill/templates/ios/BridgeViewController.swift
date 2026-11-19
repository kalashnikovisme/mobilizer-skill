import UIKit
import Capacitor

/// Capacitor's bridge view controller plus the app's own native plugins.
/// The web app (remote-URL mode) reaches them via `window.Capacitor.Plugins`.
class {{APP_PASCAL}}BridgeViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        {{BRIDGE_REGISTER_PLUGINS}}
    }
}
