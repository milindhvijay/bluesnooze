# Bluesnooze (fork)

This fork is maintained at [milindhvijay/bluesnooze](https://github.com/milindhvijay/bluesnooze). Public releases are not published yet; build from source.

## About

**Bluesnooze prevents your sleeping Mac from connecting to Bluetooth accessories.**

If you pair Bluetooth headphones or speakers with both your phone and Mac it can be frustrating when your sleeping Mac connects intermittently and disrupts the audio.

Bluesnooze turns the Bluetooth radio off when your Mac sleeps or powers off, and restores it when you unlock the Mac. Wi-Fi control is optional and off by default.

The app is menu-bar only. It has no windows, accounts, analytics or telemetry.

![Screenshot showing Bluesnooze in the status bar](images/screenshot.png)

## What it does

- Bluetooth: turns the radio off on sleep or power-off, then restores it on unlock. The default unlock action restores the previous state.
- Wi-Fi: uses the same sleep and unlock pattern when enabled. Wi-Fi control is off by default, and its default unlock action is `nothing`.
- Restores after a restart or crash: if a radio was left off by the app, the next launch restores it. The app records two internal restore markers so it can finish the restore after the process exits.
- Reports failures: if a radio change fails, the Bluetooth or Wi-Fi submenu shows `Last change failed: ...`.
- Launch at login: uses the macOS login item service. If macOS holds the item for approval, an alert opens System Settings > General > Login Items.
- Bluetooth permission is requested only when the Bluetooth settings need it.

## Installation

Minimum macOS version: 26.0

1. Open `Bluesnooze.xcodeproj` in Xcode 27.2 or later.
2. Build the `Bluesnooze` scheme.
3. Copy `Bluesnooze.app` to your `Applications` directory.
4. Launch `Bluesnooze`.
5. *Optional*: Configure <kbd>Wi-Fi</kbd> behaviour.
6. *Optional*: Configure <kbd>Launch at login</kbd>. If macOS asks, approve Bluesnooze in System Settings > General > Login Items.

Local builds are ad-hoc signed. macOS may ask for Bluetooth access again after a rebuild because the app's code signature changes.

## Usage

Click the Bluesnooze icon in the menu bar. The Bluetooth and Wi-Fi submenus set what happens when the Mac sleeps or powers off and when it unlocks. Launch at login and Hide icon are in the same menu. Quit exits the app.

## Caveats

- The app has an option to hide the icon from the status bar. To show the icon again simply launch the application a second time.
- Please note this app is not compatible with the “Allow your Apple Watch to unlock your Mac” feature.
- Turning Wi-Fi off at sleep also disables Wake on LAN, Power Nap and network-based Find My while the Mac sleeps.
- Unfortunately this app can't be distributed via the App Store because it uses a private API to switch Bluetooth on/off.

## Settings

The application settings can be modified using the `defaults` command. The keys are defined in `SettingsStore.swift`; keep this list in sync when they change.

```shell
# read settings:
defaults read com.oliverpeate.Bluesnooze disableBluetoothOnPowerDown
defaults read com.oliverpeate.Bluesnooze bluetoothActionOnScreenUnlock
defaults read com.oliverpeate.Bluesnooze disableWifiOnPowerDown
defaults read com.oliverpeate.Bluesnooze wifiActionOnScreenUnlock
defaults read com.oliverpeate.Bluesnooze hideIcon

# internal restore markers written by the app:
defaults read com.oliverpeate.Bluesnooze bluetoothRestoreOwed
defaults read com.oliverpeate.Bluesnooze wifiRestoreOwed

# update settings:
defaults write com.oliverpeate.Bluesnooze disableBluetoothOnPowerDown -bool false
defaults write com.oliverpeate.Bluesnooze bluetoothActionOnScreenUnlock -string enable
defaults write com.oliverpeate.Bluesnooze disableWifiOnPowerDown -bool true
defaults write com.oliverpeate.Bluesnooze wifiActionOnScreenUnlock -string restore
defaults write com.oliverpeate.Bluesnooze hideIcon -bool true

# delete settings: (this resets everything to defaults)
defaults delete com.oliverpeate.Bluesnooze
```

- `disableBluetoothOnPowerDown` defaults to `true`; `disableWifiOnPowerDown` defaults to `false`.
- `bluetoothActionOnScreenUnlock` defaults to `restore`; `wifiActionOnScreenUnlock` defaults to `nothing`. Valid values are `restore`, `enable` and `nothing`.
- Disabling a radio's "Turn off ..." setting also changes its unlock action from `restore` to `nothing`.
- `bluetoothRestoreOwed` and `wifiRestoreOwed` are internal markers written by the app. Do not edit them unless you are debugging a restore.

## Development

Requirements: Xcode 27.2 or later, macOS 26.0 or later, and SwiftLint for lint.

```shell
xcodebuild -project Bluesnooze.xcodeproj -scheme Bluesnooze -destination 'platform=macOS' test
swiftlint lint --strict
xcodebuild -project Bluesnooze.xcodeproj -scheme Bluesnooze -configuration Release -destination 'platform=macOS' clean build
```

The suite has 27 tests: 16 policy and 11 settings. The test target compiles `PowerPolicy.swift` and `SettingsStore.swift` directly; `AppDelegate` and `RadioController` are exercised manually. CI runs the test command on macOS 26 for pushes to `master`, pull requests and manual runs.

The app is not notarised. TCC grants reset when the build changes, so a Bluetooth prompt after a rebuild is expected.

## License

MIT. See [LICENSE](LICENSE).
