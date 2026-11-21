//
//  AppDelegate.swift
//  Bluesnooze
//
//  Created by Oliver Peate on 07/04/2020.
//  Copyright © 2020 Oliver Peate. All rights reserved.
//

import Cocoa
import LaunchAtLogin
import os

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var bluetoothMenuItem: NSMenuItem!
    @IBOutlet weak var disableBluetoothOnPowerDownMenuItem: NSMenuItem!
    @IBOutlet weak var bluetoothActionOnScreenUnlockRestore: NSMenuItem!
    @IBOutlet weak var bluetoothActionOnScreenUnlockEnable: NSMenuItem!
    @IBOutlet weak var bluetoothActionOnScreenUnlockNothing: NSMenuItem!
    @IBOutlet weak var wifiMenuItem: NSMenuItem!
    @IBOutlet weak var disableWifiOnPowerDownMenuItem: NSMenuItem!
    @IBOutlet weak var wifiActionOnScreenUnlockRestore: NSMenuItem!
    @IBOutlet weak var wifiActionOnScreenUnlockEnable: NSMenuItem!
    @IBOutlet weak var wifiActionOnScreenUnlockNothing: NSMenuItem!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!
    @IBOutlet weak var hideIconMenuItem: NSMenuItem!
    @IBOutlet weak var websiteMenuItem: NSMenuItem!

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Bluesnooze", category: "power")
    private lazy var settings = SettingsStore()
    private lazy var radios = RadioController(logger: logger)
    private lazy var bluetoothMenu = RadioMenu(
        disableOnSleepItem: disableBluetoothOnPowerDownMenuItem,
        restoreItem: bluetoothActionOnScreenUnlockRestore,
        enableItem: bluetoothActionOnScreenUnlockEnable,
        nothingItem: bluetoothActionOnScreenUnlockNothing
    )
    private lazy var wifiMenu = RadioMenu(
        disableOnSleepItem: disableWifiOnPowerDownMenuItem,
        restoreItem: wifiActionOnScreenUnlockRestore,
        enableItem: wifiActionOnScreenUnlockEnable,
        nothingItem: wifiActionOnScreenUnlockNothing
    )
    private var statusItem: NSStatusItem?
    private lazy var powerPolicy = PowerPolicy(
        bluetoothTurnedOff: settings.bluetoothRestoreOwed,
        wifiTurnedOff: settings.wifiRestoreOwed
    )
    private var notificationTokens: [NSObjectProtocol] = []
    private var bluetoothFailureMenuItem: NSMenuItem?
    private var wifiFailureMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        requestBluetoothAccessIfNeeded()
        statusMenu.autoenablesItems = false
        statusMenu.delegate = self
        setupFailureMenuItems()
        if !settings.hideIcon {
            showStatusItem()
        }
        restoreRadiosIfNeeded()
        setupNotificationHandlers()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settings.hideIcon = false
        showStatusItem()
        return true
    }

    @IBAction func disableBluetoothOnPowerDownClicked(_ sender: NSMenuItem) {
        settings.setDisableOnSleep(!settings.isDisableOnSleep(for: .bluetooth), for: .bluetooth)
        requestBluetoothAccessIfNeeded()
    }

    @IBAction func bluetoothActionOnScreenUnlockRestoreClicked(_ sender: NSMenuItem) {
        settings.setUnlockAction(.restore, for: .bluetooth)
        requestBluetoothAccessIfNeeded()
    }

    @IBAction func bluetoothActionOnScreenUnlockEnableClicked(_ sender: NSMenuItem) {
        settings.setUnlockAction(.enable, for: .bluetooth)
        requestBluetoothAccessIfNeeded()
    }

    @IBAction func bluetoothActionOnScreenUnlockNothingClicked(_ sender: NSMenuItem) {
        settings.setUnlockAction(.nothing, for: .bluetooth)
        requestBluetoothAccessIfNeeded()
    }

    @IBAction func disableWifiOnPowerDownClicked(_ sender: NSMenuItem) {
        settings.setDisableOnSleep(!settings.isDisableOnSleep(for: .wifi), for: .wifi)
    }

    @IBAction func wifiActionOnScreenUnlockRestoreClicked(_ sender: NSMenuItem) {
        settings.setUnlockAction(.restore, for: .wifi)
    }

    @IBAction func wifiActionOnScreenUnlockEnableClicked(_ sender: NSMenuItem) {
        settings.setUnlockAction(.enable, for: .wifi)
    }

    @IBAction func wifiActionOnScreenUnlockNothingClicked(_ sender: NSMenuItem) {
        settings.setUnlockAction(.nothing, for: .wifi)
    }

    @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
    }

    @IBAction func hideIconClicked(_ sender: NSMenuItem) {
        if settings.hideIcon {
            settings.hideIcon = false
            hideIconMenuItem.state = .off
        } else {
            let alert = NSAlert()
            alert.messageText = "Important information"
            alert.informativeText = "Launch the app a second time to show the icon again."
            alert.alertStyle = NSAlert.Style.informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                return
            }
            settings.hideIcon = true
            hideIconMenuItem.state = .on
            // Removing the status item while its menu is tracking is unsafe.
            DispatchQueue.main.async { [weak self] in
                self?.hideStatusItem()
            }
        }
    }

    @IBAction func websiteClicked(_ sender: NSMenuItem) {
        if let url = URL(string: "https://github.com/milindhvijay/bluesnooze") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

    func setupNotificationHandlers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.willPowerOffNotification] {
            // Workspace power notifications are posted on the main thread and an
            // observer may delay sleep while handling them, so keep this synchronous.
            let token = workspaceCenter.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                self?.handlePowerNotification()
            }
            notificationTokens.append(token)
        }

        let unlockToken = DistributedNotificationCenter.default().addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // The observer queue is main, so the assertion holds.
            MainActor.assumeIsolated {
                self?.onScreenUnlock()
            }
        }
        notificationTokens.append(unlockToken)
    }

    nonisolated private func handlePowerNotification() {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                onPowerDown()
            }
        } else {
            // The observer must finish before sleep, so hop synchronously.
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    onPowerDown()
                }
            }
        }
    }

    private func restoreRadiosIfNeeded() {
        guard settings.bluetoothRestoreOwed || settings.wifiRestoreOwed else {
            return
        }
        logger.notice("Restoring radios left off by the previous session")
        onScreenUnlock()
    }

    private func requestBluetoothAccessIfNeeded() {
        guard settings.isDisableOnSleep(for: .bluetooth)
            || settings.unlockAction(for: .bluetooth) != .nothing else {
            return
        }
        radios.requestBluetoothAccess()
    }

    func onPowerDown() {
        let bluetoothOn = radios.bluetoothOn
        let wifiOn = radios.wifiOn
        let actions = powerPolicy.sleep(
            settings: settings.policySettings,
            bluetoothOn: bluetoothOn,
            wifiOn: wifiOn
        )
        logger.notice("""
            Sleep state: Bluetooth \(String(bluetoothOn), privacy: .public), \
            Wi-Fi \(String(wifiOn), privacy: .public), \
            actions: Bluetooth \(String(describing: actions.bluetooth), privacy: .public), \
            Wi-Fi \(String(describing: actions.wifi), privacy: .public)
            """)
        if actions.bluetooth == .turnOff {
            settings.bluetoothRestoreOwed = true
        }
        if actions.wifi == .turnOff {
            settings.wifiRestoreOwed = true
        }
        radios.apply(actions)
    }

    func onScreenUnlock() {
        let actions = powerPolicy.unlock(settings: settings.policySettings)
        logger.notice("""
            Unlock actions: Bluetooth \(String(describing: actions.bluetooth), privacy: .public), \
            Wi-Fi \(String(describing: actions.wifi), privacy: .public)
            """)
        radios.apply(actions)
        settings.bluetoothRestoreOwed = false
        settings.wifiRestoreOwed = false
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshMenuState()
    }

    private func refreshMenuState() {
        let bluetoothAvailable = radios.bluetoothAvailable
        bluetoothMenuItem.isEnabled = bluetoothAvailable
        let bluetoothToolTip = """
            Bluetooth access is not available. Allow Bluesnooze in System Settings > \
            Privacy & Security > Bluetooth.
            """
        bluetoothMenuItem.toolTip = bluetoothAvailable ? nil : bluetoothToolTip
        bluetoothMenu.update(
            featureEnabled: settings.isDisableOnSleep(for: .bluetooth),
            action: settings.unlockAction(for: .bluetooth)
        )

        let wifiAvailable = radios.wifiAvailable
        wifiMenuItem.isEnabled = wifiAvailable
        wifiMenuItem.toolTip = wifiAvailable ? nil : "No Wi-Fi interface is available on this Mac."
        wifiMenu.update(
            featureEnabled: settings.isDisableOnSleep(for: .wifi),
            action: settings.unlockAction(for: .wifi)
        )

        updateFailureItem(bluetoothFailureMenuItem, failure: radios.bluetoothFailure)
        updateFailureItem(wifiFailureMenuItem, failure: radios.wifiFailure)

        launchAtLoginMenuItem.state = menuState(LaunchAtLogin.isEnabled)
        hideIconMenuItem.state = menuState(settings.hideIcon)
        websiteMenuItem.toolTip = "Version \(appVersion)"
    }

    private var appVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private func showStatusItem() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
        guard let statusItem else {
            return
        }
        if let icon = NSImage(named: "bluesnooze") {
            icon.isTemplate = true
            statusItem.button?.image = icon
        } else {
            statusItem.button?.title = "Bluesnooze"
        }
        statusItem.menu = statusMenu
    }

    private func hideStatusItem() {
        guard let statusItem else {
            return
        }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    private func menuState(_ value: Bool) -> NSControl.StateValue {
        return value ? .on : .off
    }
}

private extension AppDelegate {
    func setupFailureMenuItems() {
        let bluetoothItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        bluetoothItem.isEnabled = false
        bluetoothItem.isHidden = true
        bluetoothMenuItem.submenu?.insertItem(bluetoothItem, at: 0)
        bluetoothFailureMenuItem = bluetoothItem

        let wifiItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        wifiItem.isEnabled = false
        wifiItem.isHidden = true
        wifiMenuItem.submenu?.insertItem(wifiItem, at: 0)
        wifiFailureMenuItem = wifiItem
    }

    func updateFailureItem(_ item: NSMenuItem?, failure: String?) {
        guard let item else {
            return
        }
        if let failure {
            item.title = "Last change failed: \(failure)"
            item.isHidden = false
        } else {
            item.isHidden = true
        }
    }
}
