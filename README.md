# FloatCam

A tiny, free macOS app that puts your webcam in a floating window on top of everything else. Use it for screen recordings, demos, tutorials and presentations.

Native Swift (AppKit + AVFoundation), no dependencies, about 550 lines of code. Lives in the menu bar, uses almost no resources, and turns the camera off completely when hidden.

<!-- Add a screenshot at docs/screenshot.png and uncomment this line:
![FloatCam floating over a screen recording](docs/screenshot.png)
-->

[![Build](https://github.com/flaviort/floating-cam/actions/workflows/build.yml/badge.svg)](https://github.com/flaviort/floating-cam/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/flaviort/floating-cam)](https://github.com/flaviort/floating-cam/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- Floating camera window that stays above all apps, on every Space, even over full-screen apps
- Four shapes: circle, rounded square, 16:9 rectangle and 3:4 portrait
- Drag it anywhere, or snap it to a corner or the center from the menu
- Resize with a trackpad pinch, Option + scroll, or one of four size presets
- Works with any camera: built-in, USB, or your iPhone via Continuity Camera
- Mirror toggle and an optional white border
- Remembers shape, size, position and camera between launches
- Menu bar only, no Dock icon. Hiding the window stops the camera, so the green light goes off

## Privacy

FloatCam only shows your camera on screen. It doesn't record, save or upload anything, and it never connects to the internet. When the window is hidden the camera is fully off. The code is all here if you want to check.

## Requirements

macOS 14 Sonoma or later, on Apple Silicon or Intel.

## Install

### Option 1: Download the app (easiest)

1. Download **FloatCam.zip** from the [latest release](https://github.com/flaviort/floating-cam/releases/latest)
2. Unzip it and drag **FloatCam.app** into your **Applications** folder
3. Open it. macOS will block it the first time (see below), then ask for camera access. Click **Allow**

#### "Apple could not verify FloatCam" warning

FloatCam is free and isn't signed with a paid Apple Developer ID, so macOS shows a warning the first time you open a downloaded copy. To allow it:

1. Try to open FloatCam once and close the warning
2. Open **System Settings > Privacy & Security**
3. Scroll down to the Security section and click **Open Anyway** next to FloatCam
4. Confirm with your password or Touch ID

You only need to do this once. If you prefer the Terminal, this does the same thing:

```bash
xattr -dr com.apple.quarantine /Applications/FloatCam.app
```

The source code is all in this repo if you want to check what the app does before running it, or build it yourself with option 2 or 3.

### Option 2: Build it yourself with the installer

Apps you compile on your own Mac don't trigger the warning above. This needs Apple's free Command Line Tools; the installer offers to install them if they're missing.

1. Download this repository (**Code > Download ZIP**) and unzip it
2. Double-click **`install.command`**

It compiles FloatCam, copies it to `/Applications` and launches it.

The `install.command` file itself was downloaded from the internet, so macOS may block it the first time. Allow it the same way: **System Settings > Privacy & Security > Open Anyway**, then double-click it again.

### Option 3: Terminal

```bash
git clone https://github.com/flaviort/floating-cam.git
cd floating-cam
./install.command
```

Or build without installing:

```bash
./build.sh
open build/FloatCam.app
```

## Usage

When FloatCam starts, the camera appears in the bottom-right corner and a webcam icon shows up in the menu bar.

| Action | How |
| --- | --- |
| Move | Drag the video |
| Change shape | Double-click the video |
| Resize | Pinch on the trackpad, or hold Option (⌥) and scroll |
| Open the menu | Right-click the video, or click the menu bar icon |
| Show / hide | Menu > Show/Hide camera (⌘C while the menu is open) |
| Quit | Menu > Quit FloatCam (⌘Q while the menu is open) |

The menu also has **Shape**, **Size**, **Position** and **Camera** options, plus toggles for **Mirror video**, **Always on top** and **Show border**.

### Tips for recording

- FloatCam shows up in screen recordings like any other window, so QuickTime, OBS, Loom and the macOS screenshot toolbar (⇧⌘5) all capture it.
- The video is mirrored by default so it feels like a mirror to you. Turn **Mirror video** off if text behind you should read correctly in the recording.

## Troubleshooting

**The window is black.** Check that FloatCam is allowed in **System Settings > Privacy & Security > Camera**, and that no other app is holding the camera exclusively.

**It keeps asking for camera permission.** This happens after every rebuild because local builds are ad-hoc signed. The release download keeps its permission between launches.

**I can't find the window.** Click the menu bar icon and choose **Position > Bottom right**.

**Reset camera permission:**

```bash
tccutil reset Camera com.flaviort.floatcam
```

## Uninstall

Quit FloatCam from the menu, then:

```bash
rm -rf /Applications/FloatCam.app
defaults delete com.flaviort.floatcam
```

## Building and contributing

The whole app is five Swift files compiled straight with `swiftc`. No Xcode project.

```
floating-cam/
├── Sources/
│   ├── main.swift            # App entry point
│   ├── AppDelegate.swift     # Menu bar, menus, shape/size/position logic
│   ├── CameraManager.swift   # AVCaptureSession and camera switching
│   ├── CameraWindow.swift    # Floating borderless window and masked video view
│   └── Settings.swift        # Shapes and saved preferences
├── Resources/AppIcon.icns     # App icon
├── scripts/make-icon.swift   # Draws the icon (swift scripts/make-icon.swift)
├── Info.plist                # Bundle config and camera usage text
├── build.sh                  # Compiles build/FloatCam.app (--universal for Intel + Apple Silicon)
└── install.command           # Builds and installs into /Applications
```

Bug reports and pull requests are welcome. For anything bigger than a small fix, open an issue first so we can agree on the approach.

### Releasing

Releases are built by GitHub Actions. Update the version in `Info.plist` and `CHANGELOG.md`, then push a tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow builds a universal app and attaches `FloatCam.zip` to a new GitHub release.

## Roadmap

- [ ] Global keyboard shortcut to show/hide
- [ ] Launch at login
- [ ] Zoom and crop
- [ ] Color filters and background blur
- [ ] Homebrew cask

## License

[MIT](LICENSE). Free to use, change and share.
