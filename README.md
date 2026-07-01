# Browser Project - CLI Deployment Guide

This guide provides the necessary commands to build, install, and launch the app on a physical device using the command line.

## Prerequisites

- Physical iPhone connected via USB or Wi-Fi.
- Device ID: `00008142-001E415022F3801C`

## Signing setup

On a fresh clone, the project opens but won't sign until you create your local override:

```sh
cp Config/Local.xcconfig.example Config/Local.xcconfig
# then edit it: DEVELOPMENT_TEAM = <your 10-char Team ID>
```

## Deployment Blueprint

You can run the entire process (Build, Install, Launch) using the macro script:

```bash
./deploy.sh
```

Alternatively, here are the individual steps:

### 1. Build the App

Compiles the source code for the specific device architecture and places the output in a local `./build` folder.

```bash
xcodebuild -scheme "browser" -destination 'id=00008142-001E415022F3801C' -derivedDataPath ./build clean build
```

### 2. Install to Device

Transfers the compiled `.app` bundle from your Mac to the physical iPhone.

```bash
xcrun devicectl device install app --device 00008142-001E415022F3801C ./build/Build/Products/Debug-iphoneos/browser.app
```

### 3. Launch App

Triggers the app to open on the device.

```bash
xcrun devicectl device process launch --device 00008142-001E415022F3801C --console thedwncmpy.browser
```

---

## Combined One-Liner

Run all steps at once. The process will stop if any step fails.

```bash
xcodebuild -scheme "browser" -destination 'id=00008142-001E415022F3801C' -derivedDataPath ./build clean build && \
xcrun devicectl device install app --device 00008142-001E415022F3801C ./build/Build/Products/Debug-iphoneos/browser.app && \
xcrun devicectl device process launch --device 00008142-001E415022F3801C thedwncmpy.browser
```

---

## Key Terminology

### Bundle Identifier (`thedwncmpy.browser`)

The **Bundle ID** is a unique string that identifies your app in the Apple ecosystem.

- **Uniqueness:** It ensures iOS updates the existing app instead of installing a duplicate.
- **Reverse DNS:** It follows the format `com.companyname.appname`.
- **Location:** Found in Xcode under **Target > General > Bundle Identifier**.

### Derived Data (`-derivedDataPath ./build`)

By default, Xcode stores build products in a hidden folder. Using this flag forces the output into the `./build` directory in your project folder, making it easy to locate the `.app` file for the installation step.

### Clean Build

Adding `clean` before `build` deletes old compiled files. This ensures that your latest code changes are fully applied and prevents "ghost" bugs from previous versions.
