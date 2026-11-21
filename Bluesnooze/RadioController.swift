import CoreBluetooth
import CoreWLAN
import IOBluetooth // Links the framework that exports the private preference setter.
import os

@MainActor
final class RadioController: NSObject, CBCentralManagerDelegate {
    private let logger: Logger
    private var bluetoothState: CBManagerState = .unknown
    private lazy var bluetoothManager = CBCentralManager(
        delegate: self,
        queue: nil, // The main queue keeps bluetoothState main-confined.
        options: [CBCentralManagerOptionShowPowerAlertKey: false]
    )

    init(logger: Logger) {
        self.logger = logger
        super.init()
    }

    func requestBluetoothAccess() {
        _ = bluetoothManager
        bluetoothState = bluetoothManager.state
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        MainActor.assumeIsolated {
            bluetoothState = state
            if state == .unauthorized {
                logger.error("""
                    Bluetooth access is denied. Allow Bluesnooze in System Settings > \
                    Privacy & Security > Bluetooth.
                    """)
            }
        }
    }

    var bluetoothOn: Bool {
        return bluetoothState == .poweredOn
    }

    var bluetoothAvailable: Bool {
        guard bluetoothState != .unsupported, bluetoothState != .unauthorized else {
            return false
        }
        switch CBManager.authorization {
        case .denied, .restricted:
            return false
        case .notDetermined, .allowedAlways:
            return true
        @unknown default:
            return false
        }
    }

    var wifiAvailable: Bool {
        return wifiInterface != nil
    }

    var wifiOn: Bool {
        return wifiInterface?.powerOn() ?? false
    }

    func apply(_ actions: RadioActions) {
        apply(actions.bluetooth, to: setBluetooth)
        apply(actions.wifi, to: setWifi)
    }

    private func apply(_ action: RadioAction, to set: (Bool) -> Void) {
        switch action {
        case .turnOn:
            set(true)
        case .turnOff:
            set(false)
        case .nothing:
            break
        }
    }

    private var wifiInterface: CWInterface? {
        return CWWiFiClient.shared().interface()
    }

    private func setBluetooth(_ powerOn: Bool) {
        guard bluetoothAvailable else {
            logger.error("Bluetooth is unavailable; cannot change power.")
            return
        }
        guard bluetoothOn != powerOn else {
            return
        }
        // Private API: see the decision record in Plane. The setter returns void
        // and there is no public state to confirm, so this is best effort.
        IOBluetoothPreferenceSetControllerPowerState(powerOn ? 1 : 0)
    }

    private func setWifi(_ powerOn: Bool) {
        guard let interface = wifiInterface else {
            logger.error("No Wi-Fi interface available")
            return
        }
        guard interface.powerOn() != powerOn else {
            return
        }
        do {
            try interface.setPower(powerOn)
        } catch {
            logger.error("Wi-Fi power change failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
