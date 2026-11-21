import CoreBluetooth
import CoreWLAN
import IOBluetooth // Links the framework that exports the private preference setter.
import os

final class RadioController {
    private let logger: Logger
    private lazy var bluetoothManager = CBCentralManager(
        delegate: nil,
        queue: nil,
        options: [CBCentralManagerOptionShowPowerAlertKey: false]
    )

    init(logger: Logger) {
        self.logger = logger
        _ = bluetoothManager // Ask for Bluetooth access while the user is present.
    }

    var bluetoothOn: Bool {
        return bluetoothManager.state == .poweredOn
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
