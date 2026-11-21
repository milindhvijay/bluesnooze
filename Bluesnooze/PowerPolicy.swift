enum RadioAction: Equatable {
    case turnOn
    case turnOff
    case nothing
}

struct RadioActions: Equatable {
    let bluetooth: RadioAction
    let wifi: RadioAction
}

/// Decides what to do with each radio around sleep and unlock. No I/O, no defaults,
/// no global state, so the behaviour can be tested without a Mac radio.
struct PowerPolicy {
    enum UnlockAction: String, Equatable {
        case restore
        case enable
        case nothing
    }

    struct Settings: Equatable {
        let disableBluetoothOnPowerDown: Bool
        let bluetoothActionOnScreenUnlock: UnlockAction
        let disableWifiOnPowerDown: Bool
        let wifiActionOnScreenUnlock: UnlockAction
    }

    private struct Snapshot {
        var turnedOff = false
    }

    private var bluetooth = Snapshot()
    private var wifi = Snapshot()

    mutating func sleep(settings: Settings, bluetoothOn: Bool, wifiOn: Bool) -> RadioActions {
        let bluetoothAction: RadioAction = settings.disableBluetoothOnPowerDown && bluetoothOn ? .turnOff : .nothing
        let wifiAction: RadioAction = settings.disableWifiOnPowerDown && wifiOn ? .turnOff : .nothing

        bluetooth.turnedOff = bluetooth.turnedOff || bluetoothAction == .turnOff
        wifi.turnedOff = wifi.turnedOff || wifiAction == .turnOff

        return RadioActions(bluetooth: bluetoothAction, wifi: wifiAction)
    }

    mutating func unlock(settings: Settings) -> RadioActions {
        let actions = RadioActions(
            bluetooth: action(for: settings.bluetoothActionOnScreenUnlock, snapshot: bluetooth),
            wifi: action(for: settings.wifiActionOnScreenUnlock, snapshot: wifi)
        )
        reset()
        return actions
    }

    private func action(for setting: UnlockAction, snapshot: Snapshot) -> RadioAction {
        switch setting {
        case .nothing:
            return .nothing
        case .enable:
            return .turnOn
        case .restore:
            return snapshot.turnedOff ? .turnOn : .nothing
        }
    }

    private mutating func reset() {
        bluetooth = Snapshot()
        wifi = Snapshot()
    }
}
