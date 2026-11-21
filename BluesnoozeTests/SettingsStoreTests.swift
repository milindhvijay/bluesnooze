import XCTest

final class SettingsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: SettingsStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "BluesnoozeTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        store = SettingsStore(defaults: defaults)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        try super.tearDownWithError()
    }

    func testDefaults() {
        XCTAssertTrue(store.isDisableOnSleep(for: .bluetooth))
        XCTAssertTrue(store.isDisableOnSleep(for: .wifi))
        XCTAssertEqual(store.unlockAction(for: .bluetooth), .restore)
        XCTAssertEqual(store.unlockAction(for: .wifi), .restore)
        XCTAssertFalse(store.hideIcon)
    }

    func testKeyNamesAreThePublicContract() {
        XCTAssertEqual(SettingsStore.Key.disableBluetoothOnPowerDown, "disableBluetoothOnPowerDown")
        XCTAssertEqual(SettingsStore.Key.bluetoothActionOnScreenUnlock, "bluetoothActionOnScreenUnlock")
        XCTAssertEqual(SettingsStore.Key.disableWifiOnPowerDown, "disableWifiOnPowerDown")
        XCTAssertEqual(SettingsStore.Key.wifiActionOnScreenUnlock, "wifiActionOnScreenUnlock")
        XCTAssertEqual(SettingsStore.Key.hideIcon, "hideIcon")
        XCTAssertEqual(SettingsStore.Key.bluetoothRestoreOwed, "bluetoothRestoreOwed")
        XCTAssertEqual(SettingsStore.Key.wifiRestoreOwed, "wifiRestoreOwed")

        defaults.set("nothing", forKey: "wifiActionOnScreenUnlock")
        XCTAssertEqual(store.unlockAction(for: .wifi), .nothing)
    }

    func testActionReadWrite() {
        store.setUnlockAction(.enable, for: .bluetooth)
        store.setUnlockAction(.restore, for: .wifi)

        XCTAssertEqual(store.unlockAction(for: .bluetooth), .enable)
        XCTAssertEqual(store.unlockAction(for: .wifi), .restore)
    }

    func testCorruptActionsFallBackToDefaults() {
        defaults.set("bogus", forKey: SettingsStore.Key.bluetoothActionOnScreenUnlock)
        defaults.set("bogus", forKey: SettingsStore.Key.wifiActionOnScreenUnlock)

        XCTAssertEqual(store.unlockAction(for: .bluetooth), .restore)
        XCTAssertEqual(store.unlockAction(for: .wifi), .restore)
    }

    func testDisablingFeatureDemotesRestore() {
        store.setUnlockAction(.restore, for: .bluetooth)

        store.setDisableOnSleep(false, for: .bluetooth)

        XCTAssertFalse(store.isDisableOnSleep(for: .bluetooth))
        XCTAssertEqual(store.unlockAction(for: .bluetooth), .nothing)
    }

    func testDisablingWifiFeatureDemotesRestore() {
        store.setUnlockAction(.restore, for: .wifi)

        store.setDisableOnSleep(false, for: .wifi)

        XCTAssertFalse(store.isDisableOnSleep(for: .wifi))
        XCTAssertEqual(store.unlockAction(for: .wifi), .nothing)
        XCTAssertTrue(store.isDisableOnSleep(for: .bluetooth))
        XCTAssertEqual(store.unlockAction(for: .bluetooth), .restore)
    }

    func testEnablingFeaturePreservesRestore() {
        store.setUnlockAction(.restore, for: .wifi)

        store.setDisableOnSleep(true, for: .wifi)

        XCTAssertTrue(store.isDisableOnSleep(for: .wifi))
        XCTAssertEqual(store.unlockAction(for: .wifi), .restore)
    }

    func testPolicySettingsMapsStore() {
        store.setUnlockAction(.enable, for: .bluetooth)
        store.setDisableOnSleep(true, for: .bluetooth)
        store.setUnlockAction(.restore, for: .wifi)
        store.setDisableOnSleep(true, for: .wifi)

        let settings = store.policySettings

        XCTAssertTrue(settings.disableBluetoothOnPowerDown)
        XCTAssertEqual(settings.bluetoothActionOnScreenUnlock, .enable)
        XCTAssertTrue(settings.disableWifiOnPowerDown)
        XCTAssertEqual(settings.wifiActionOnScreenUnlock, .restore)
    }

    func testHideIcon() {
        XCTAssertFalse(store.hideIcon)

        store.hideIcon = true
        XCTAssertTrue(store.hideIcon)

        store.hideIcon = false
        XCTAssertFalse(store.hideIcon)
    }

    func testRestoreFlagsDefaultToFalse() {
        XCTAssertFalse(store.bluetoothRestoreOwed)
        XCTAssertFalse(store.wifiRestoreOwed)
    }

    func testRestoreFlagsRoundTrip() {
        store.bluetoothRestoreOwed = true
        store.wifiRestoreOwed = true

        XCTAssertTrue(store.bluetoothRestoreOwed)
        XCTAssertTrue(store.wifiRestoreOwed)

        store.bluetoothRestoreOwed = false
        store.wifiRestoreOwed = false

        XCTAssertFalse(store.bluetoothRestoreOwed)
        XCTAssertFalse(store.wifiRestoreOwed)
    }
}
