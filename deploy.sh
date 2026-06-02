#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Configuration ---
DEVICE_ID="00008142-001E415022F3801C"
SCHEME="browser"
BUNDLE_ID="thedwncmpy.browser"
APP_PATH="./build/Build/Products/Debug-iphoneos/browser.app"

# --- Colors for output ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Step 1: Building ${SCHEME}...${NC}"
xcodebuild -scheme "$SCHEME" \
           -destination "id=$DEVICE_ID" \
           -derivedDataPath ./build \
           clean build

echo -e "${BLUE}📲 Step 2: Installing to device ${DEVICE_ID}...${NC}"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo -e "${GREEN}🎬 Step 3: Launching ${BUNDLE_ID} with Console...${NC}"
xcrun devicectl device process launch --device "$DEVICE_ID" --console "$BUNDLE_ID"
