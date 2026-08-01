# Calibrate

A personal iOS app that sets communication apps aside when you decide you're not in a good headspace
to be sending messages. Built from `calibratebrief.docx`.

Two ways to start a pause, both able to run at once:

- **Take a Pause** — a manual button with a cooldown you pick (15 min / 30 min / 1 hr / 2 hr, or
  custom). No early override.
- **Quiet hours** — recurring windows like weeknights 10 PM–7 AM, applied and lifted automatically.

Everything runs on-device. No backend, no accounts, no analytics.

---

## Before you build

Two hard prerequisites, both outside the code:

1. **A paid Apple Developer Program membership.** The `com.apple.developer.family-controls`
   entitlement and App Groups aren't available to a free personal team. Without it the project won't
   sign.
2. **A physical iPhone running iOS 16 or later.** Screen Time APIs are inert in the Simulator —
   `FamilyActivityPicker` comes up empty and shields never apply. Testing on the Simulator will look
   like the app is broken when it isn't.

This project has never been compiled. It was written without access to Xcode or a Swift toolchain,
so expect to fix a few small things on first build.

## Setup

```
open Calibrate.xcodeproj
```

Then, once:

1. Select the project → each of the three targets (`Calibrate`, `CalibrateMonitor`,
   `CalibrateShield`) → **Signing & Capabilities** → set your Team.
2. Bundle IDs default to `com.toombsc.calibrate`, `.monitor`, and `.shield`. If you change the root,
   change all three, keeping the extensions as children of the app.
3. Confirm each target shows **Family Controls** and **App Groups** with
   `group.com.toombsc.calibrate` checked. The entitlement files already declare both — this is just
   verifying Xcode registered them with your account.
4. Build to your device.

If you change the App Group ID, update `SharedStore.appGroupID` to match. When they disagree,
Settings shows a warning rather than failing silently.

## How it's put together

| Target | What it does |
|---|---|
| `Calibrate` | SwiftUI app — the three screens from the brief |
| `CalibrateMonitor` | `DeviceActivityMonitor` — applies and lifts shields at window boundaries, including while the app is closed |
| `CalibrateShield` | `ShieldConfigurationDataSource` — the "Taking a pause" screen you see when you tap a paused app |

The three share `SharedStore`, `PauseSchedule`, `PauseState`, and `Theme` through an App Group. The
extensions run in their own processes, so the App Group is the only channel between them.

Four details worth knowing before changing anything:

- **A manual pause outlives the app.** An in-process `Timer` dies when you force-quit, so starting a
  pause also registers a one-off `DeviceActivitySchedule`; the extension gets woken at the end and
  lifts the shield. `manualPauseEnd` in the shared store is a third backstop — `PauseCoordinator`
  checks it against the clock on every foreground and clears a shield that outlived its timer.
- **15 minutes is a floor, not a preference.** `DeviceActivitySchedule` rejects shorter intervals.
- **Schedules cost one registration per weekday.** `DeviceActivitySchedule` repeats daily and has no
  day-of-week field, so "weeknights" is five registrations. iOS allows about 20 concurrently;
  Settings shows the running total and refuses a save that would exceed it.
- **The extensions stay small.** They run under tight memory limits, and getting killed there means a
  shield that never lifts.

## Test checklist

In order — step 6 is the one that matters.

1. Project opens, three targets in the navigator.
2. Signing set on all three, capabilities present.
3. Builds and installs to a physical device.
4. First launch asks for Screen Time access; approving requires your passcode.
5. Pick apps in Settings, then Take a Pause → 15 min. Selected apps shield right away, and tapping
   one shows the sage "Taking a pause" screen rather than Apple's gray default.
6. **Force-quit Calibrate while paused.** The shield should still lift on its own at expiry.
7. Add a window starting ~2 minutes out, ending ~20 minutes out. It should engage and lift without
   opening the app. Then check a cross-midnight weeknight window survives midnight.
8. Mid-pause: no unlock control anywhere, and Settings is read-only.

## Not built

Per §9 of the brief: App Store submission, accountability partners, check-ins and mood tracking,
notification suppression, usage history, widget and Watch app.

The brief also flags the no-early-override rule as worth revisiting after real use. If it turns out
too rigid, the place to add a long-press escape hatch with a secondary cooldown is
`HomeActiveView` plus a new method on `PauseCoordinator` — nothing else needs to change.
