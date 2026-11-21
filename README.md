# Bluesnooze (fork)

This fork is maintained at [milindhvijay/bluesnooze](https://github.com/milindhvijay/bluesnooze). Public releases are not published yet; build from source.

## About

**Bluesnooze prevents your sleeping Mac from connecting to Bluetooth accessories.**

If you pair Bluetooth headphones or speakers with both your phone & Mac it can be frustrating when your sleeping Mac connects intermittently and disrupts the audio.

With Bluesnooze the Bluetooth connection is switched off when your Mac sleeps, and switched on when your Mac wakes.

Bluesnooze can also manage the Wi-Fi connection in the same way (disabled by default).

![Screenshot showing Bluesnooze in the status bar](images/screenshot.png)

## Installation

Minimum macOS version: 26.0

1. Open `Bluesnooze.xcodeproj` in Xcode 27.2 or later.
1. Build the `Bluesnooze` scheme.
1. Copy `Bluesnooze.app` to your `Applications` directory.
1. Launch `Bluesnooze`.
1. *Optional*: Configure <kbd>Wi-Fi</kbd> behaviour.
1. *Optional*: Configure <kbd>Launch at login</kbd>.

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
