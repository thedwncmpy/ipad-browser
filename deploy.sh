#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# --- Configuration ---
DEVICE_ID="00008142-001E415022F3801C"
SCHEME="browser"
BUNDLE_ID="thedwncmpy.browser"
APP_PATH="./build/Build/Products/Debug-iphoneos/browser.app"
LOG_DIR="./logs"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/deploy-${TIMESTAMP}.log"
CURRENT_STEP="startup"

# --- Colors for output ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
  local exit_code=$?
  echo -e "${RED}Build failed during: ${CURRENT_STEP}${NC}"
  echo "Exit code: ${exit_code}"
  echo "Full log: ${LOG_FILE}"
  exit "$exit_code"
}

trap on_error ERR

echo "Logging deploy output to ${LOG_FILE}"

CURRENT_STEP="build"
echo -e "${BLUE}🚀 Step 1: Building ${SCHEME}...${NC}"
xcodebuild -scheme "$SCHEME" \
           -destination "id=$DEVICE_ID" \
           -derivedDataPath ./build \
           clean build

CURRENT_STEP="install"
echo -e "${BLUE}📲 Step 2: Installing to device ${DEVICE_ID}...${NC}"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

CURRENT_STEP="launch"
echo -e "${GREEN}🎬 Step 3: Launching ${BUNDLE_ID} with Console...${NC}"
xcrun devicectl device process launch --device "$DEVICE_ID" --console "$BUNDLE_ID"

echo -e "${GREEN}Deploy completed successfully.${NC}"
echo "Full log: ${LOG_FILE}"
