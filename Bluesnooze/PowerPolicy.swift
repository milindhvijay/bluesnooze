import Foundation

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

    private var bluetoothWasOn = false
    private var wifiWasOn = false
    private var bluetoothTurnedOff = false
    private var wifiTurnedOff = false

    mutating func sleep(settings: Settings, bluetoothOn: Bool, wifiOn: Bool) -> RadioActions {
        bluetoothWasOn = bluetoothOn
        wifiWasOn = wifiOn
        bluetoothTurnedOff = settings.disableBluetoothOnPowerDown
        wifiTurnedOff = settings.disableWifiOnPowerDown

        return RadioActions(
            bluetooth: settings.disableBluetoothOnPowerDown ? .turnOff : .nothing,
            wifi: settings.disableWifiOnPowerDown ? .turnOff : .nothing
        )
    }

    mutating func unlock(settings: Settings) -> RadioActions {
        let actions = RadioActions(
            bluetooth: action(
                for: settings.bluetoothActionOnScreenUnlock,
                wasOn: bluetoothWasOn,
                turnedOff: bluetoothTurnedOff
            ),
            wifi: action(
                for: settings.wifiActionOnScreenUnlock,
                wasOn: wifiWasOn,
                turnedOff: wifiTurnedOff
            )
        )
        reset()
        return actions
    }

    private func action(for setting: UnlockAction, wasOn: Bool, turnedOff: Bool) -> RadioAction {
        switch setting {
        case .nothing:
            return .nothing
        case .enable:
            return .turnOn
        case .restore:
            return turnedOff && wasOn ? .turnOn : .nothing
        }
    }

    private mutating func reset() {
        bluetoothWasOn = false
        wifiWasOn = false
        bluetoothTurnedOff = false
        wifiTurnedOff = false
    }
}
