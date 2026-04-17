# Lockey

Lockey is a lightweight macOS menu bar utility that temporarily suppresses keyboard input so you can clean your keyboard without triggering accidental key presses.

## Why Lockey

When cleaning a keyboard, accidental key presses can trigger shortcuts, type into active apps, and disrupt your session. Lockey provides a quick lock/unlock flow directly from the menu bar.

## Features

- Menu bar-only control surface (no extra popup windows)
- One-click keyboard lock and manual unlock
- Suppresses standard keyboard events while active
- Attempts to suppress media/function-row system-defined key events (for example brightness and volume keys)
- Accessibility permission guidance in-app

## Limitations

- Touch ID / power lock hardware actions are controlled by macOS security layers and cannot be intercepted by a normal user-space app.
- Some protected system contexts may not allow full event interception.

## Requirements

- macOS 14 or later
- Accessibility permission enabled for Lockey in:
  - `System Settings > Privacy & Security > Accessibility`

## Build and Run

```bash
./script/build_and_run.sh
```

Useful modes:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --debug
```

## Testing

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

## Project Layout

- `Sources/Lockey/`: menu bar app shell and UI
- `Sources/LockeyKit/`: core state machine, permission handling, and interception services
- `Tests/LockeyKitTests/`: unit tests for controller and keyboard interception behavior
- `script/build_and_run.sh`: local build, bundle, and launch entrypoint

## Status

Lockey is currently focused on a compact v1 experience for personal/direct use.
