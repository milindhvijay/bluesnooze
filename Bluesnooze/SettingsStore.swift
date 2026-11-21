import Foundation

struct SettingsStore {
    enum Radio {
        case bluetooth
        case wifi
    }

    enum Key {
        static let disableBluetoothOnPowerDown = "disableBluetoothOnPowerDown"
        static let bluetoothActionOnScreenUnlock = "bluetoothActionOnScreenUnlock"
        static let disableWifiOnPowerDown = "disableWifiOnPowerDown"
        static let wifiActionOnScreenUnlock = "wifiActionOnScreenUnlock"
        static let hideIcon = "hideIcon"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.disableBluetoothOnPowerDown: true,
            Key.disableWifiOnPowerDown: false,
            Key.bluetoothActionOnScreenUnlock: defaultUnlockAction(for: .bluetooth).rawValue,
            Key.wifiActionOnScreenUnlock: defaultUnlockAction(for: .wifi).rawValue,
            Key.hideIcon: false
        ])
    }

    var hideIcon: Bool {
        get {
            return defaults.bool(forKey: Key.hideIcon)
        }
        set {
            defaults.set(newValue, forKey: Key.hideIcon)
        }
    }

    func isDisableOnSleep(for radio: Radio) -> Bool {
        defaults.bool(forKey: disableKey(for: radio))
    }

    func setDisableOnSleep(_ enabled: Bool, for radio: Radio) {
        defaults.set(enabled, forKey: disableKey(for: radio))
        if !enabled && unlockAction(for: radio) == .restore {
            setUnlockAction(.nothing, for: radio)
        }
    }

    func unlockAction(for radio: Radio) -> PowerPolicy.UnlockAction {
        guard let raw = defaults.string(forKey: actionKey(for: radio)),
              let action = PowerPolicy.UnlockAction(rawValue: raw) else {
            return defaultUnlockAction(for: radio)
        }
        return action
    }

    func setUnlockAction(_ action: PowerPolicy.UnlockAction, for radio: Radio) {
        defaults.set(action.rawValue, forKey: actionKey(for: radio))
    }

    var policySettings: PowerPolicy.Settings {
        PowerPolicy.Settings(
            disableBluetoothOnPowerDown: isDisableOnSleep(for: .bluetooth),
            bluetoothActionOnScreenUnlock: unlockAction(for: .bluetooth),
            disableWifiOnPowerDown: isDisableOnSleep(for: .wifi),
            wifiActionOnScreenUnlock: unlockAction(for: .wifi)
        )
    }

    private func disableKey(for radio: Radio) -> String {
        switch radio {
        case .bluetooth:
            return Key.disableBluetoothOnPowerDown
        case .wifi:
            return Key.disableWifiOnPowerDown
        }
    }

    private func actionKey(for radio: Radio) -> String {
        switch radio {
        case .bluetooth:
            return Key.bluetoothActionOnScreenUnlock
        case .wifi:
            return Key.wifiActionOnScreenUnlock
        }
    }

    private func defaultUnlockAction(for radio: Radio) -> PowerPolicy.UnlockAction {
        switch radio {
        case .bluetooth:
            return .restore
        case .wifi:
            return .nothing
        }
    }
}
