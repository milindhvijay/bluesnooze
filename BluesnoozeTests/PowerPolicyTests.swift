import XCTest

final class PowerPolicyTests: XCTestCase {
    private let bothRestore = PowerPolicy.Settings(
        disableBluetoothOnPowerDown: true,
        bluetoothActionOnScreenUnlock: .restore,
        disableWifiOnPowerDown: true,
        wifiActionOnScreenUnlock: .restore
    )

    func testSleepTurnsOffEnabledRadios() {
        var policy = PowerPolicy()

        let actions = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOff, wifi: .turnOff))
    }

    func testSleepDoesNotTurnOffRadiosThatAreAlreadyOff() {
        var policy = PowerPolicy()

        let actions = policy.sleep(settings: bothRestore, bluetoothOn: false, wifiOn: false)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testSleepLeavesDisabledRadiosAlone() {
        let settings = PowerPolicy.Settings(
            disableBluetoothOnPowerDown: true,
            bluetoothActionOnScreenUnlock: .restore,
            disableWifiOnPowerDown: false,
            wifiActionOnScreenUnlock: .restore
        )
        var policy = PowerPolicy()

        let actions = policy.sleep(settings: settings, bluetoothOn: true, wifiOn: true)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOff, wifi: .nothing))
    }

    func testRestoreTurnsOnRadiosThatWereOnAndWereTurnedOff() {
        var policy = PowerPolicy()
        _ = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)

        let actions = policy.unlock(settings: bothRestore)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOn, wifi: .turnOn))
    }

    func testRestoreLeavesRadiosOffWhenTheyWereAlreadyOff() {
        var policy = PowerPolicy()
        _ = policy.sleep(settings: bothRestore, bluetoothOn: false, wifiOn: false)

        let actions = policy.unlock(settings: bothRestore)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testRestoreDoesNothingWithoutASleep() {
        var policy = PowerPolicy()

        let actions = policy.unlock(settings: bothRestore)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testRestoreDoesNotTurnOnARadioTheAppDidNotTurnOff() {
        let settings = PowerPolicy.Settings(
            disableBluetoothOnPowerDown: false,
            bluetoothActionOnScreenUnlock: .restore,
            disableWifiOnPowerDown: false,
            wifiActionOnScreenUnlock: .restore
        )
        var policy = PowerPolicy()
        _ = policy.sleep(settings: settings, bluetoothOn: true, wifiOn: true)

        let actions = policy.unlock(settings: settings)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testEnableTurnsOnWithoutASleep() {
        let settings = PowerPolicy.Settings(
            disableBluetoothOnPowerDown: false,
            bluetoothActionOnScreenUnlock: .enable,
            disableWifiOnPowerDown: false,
            wifiActionOnScreenUnlock: .enable
        )
        var policy = PowerPolicy()

        let actions = policy.unlock(settings: settings)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOn, wifi: .turnOn))
    }

    func testNothingLeavesRadiosAlone() {
        let settings = PowerPolicy.Settings(
            disableBluetoothOnPowerDown: true,
            bluetoothActionOnScreenUnlock: .nothing,
            disableWifiOnPowerDown: true,
            wifiActionOnScreenUnlock: .nothing
        )
        var policy = PowerPolicy()
        _ = policy.sleep(settings: settings, bluetoothOn: true, wifiOn: true)

        let actions = policy.unlock(settings: settings)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testUnlockConsumesTheSnapshot() {
        var policy = PowerPolicy()
        _ = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)
        _ = policy.unlock(settings: bothRestore)

        let secondUnlock = policy.unlock(settings: bothRestore)

        XCTAssertEqual(secondUnlock, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testSecondSleepReArmsTheSnapshot() {
        var policy = PowerPolicy()
        _ = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)
        _ = policy.unlock(settings: bothRestore)
        _ = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)

        let actions = policy.unlock(settings: bothRestore)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOn, wifi: .turnOn))
    }

    func testSecondSleepKeepsTheSnapshotArmed() {
        var policy = PowerPolicy()
        _ = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)
        _ = policy.sleep(settings: bothRestore, bluetoothOn: false, wifiOn: false)

        let actions = policy.unlock(settings: bothRestore)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOn, wifi: .turnOn))
    }

    func testCurrentSettingsControlTheUnlockAction() {
        var policy = PowerPolicy()
        _ = policy.sleep(settings: bothRestore, bluetoothOn: true, wifiOn: true)
        let changed = PowerPolicy.Settings(
            disableBluetoothOnPowerDown: true,
            bluetoothActionOnScreenUnlock: .nothing,
            disableWifiOnPowerDown: true,
            wifiActionOnScreenUnlock: .enable
        )

        let actions = policy.unlock(settings: changed)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .turnOn))
    }

    func testRestoringAtLaunchTurnsOnRadiosLeftOff() {
        var policy = PowerPolicy(bluetoothTurnedOff: true, wifiTurnedOff: true)

        let actions = policy.unlock(settings: bothRestore)

        XCTAssertEqual(actions, RadioActions(bluetooth: .turnOn, wifi: .turnOn))
    }

    func testRestoringAtLaunchRespectsNothing() {
        let settings = PowerPolicy.Settings(
            disableBluetoothOnPowerDown: true,
            bluetoothActionOnScreenUnlock: .nothing,
            disableWifiOnPowerDown: true,
            wifiActionOnScreenUnlock: .nothing
        )
        var policy = PowerPolicy(bluetoothTurnedOff: true, wifiTurnedOff: true)

        let actions = policy.unlock(settings: settings)

        XCTAssertEqual(actions, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }

    func testRestoreAtLaunchConsumesTheSnapshot() {
        var policy = PowerPolicy(bluetoothTurnedOff: true, wifiTurnedOff: true)
        _ = policy.unlock(settings: bothRestore)

        let secondUnlock = policy.unlock(settings: bothRestore)

        XCTAssertEqual(secondUnlock, RadioActions(bluetooth: .nothing, wifi: .nothing))
    }
}
