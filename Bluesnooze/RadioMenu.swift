import AppKit

struct RadioMenu {
    let disableOnSleepItem: NSMenuItem
    let restoreItem: NSMenuItem
    let enableItem: NSMenuItem
    let nothingItem: NSMenuItem

    func update(featureEnabled: Bool, action: PowerPolicy.UnlockAction) {
        disableOnSleepItem.state = state(featureEnabled)
        restoreItem.isEnabled = featureEnabled
        restoreItem.state = restoreState(featureEnabled: featureEnabled, action: action)
        enableItem.state = state(action == .enable)
        nothingItem.state = state(action == .nothing)
    }

    private func state(_ value: Bool) -> NSControl.StateValue {
        return value ? .on : .off
    }

    private func restoreState(featureEnabled: Bool, action: PowerPolicy.UnlockAction) -> NSControl.StateValue {
        guard action == .restore else {
            return .off
        }
        return featureEnabled ? .on : .mixed
    }
}
