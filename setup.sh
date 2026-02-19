#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Biblically — full terminal setup script
# Run from inside the biblically-app/ folder:
#   cd /Users/rehandominic/Documents/claude-code/biblically-app
#   chmod +x setup.sh
#   ./setup.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

# ── 0. Helpers ───────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}▶ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
err_exit(){ echo -e "${RED}✗ $*${NC}"; exit 1; }

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# ── 1. Check for Xcode command-line tools ────────────────────
info "Checking Xcode Command Line Tools…"
xcode-select -p &>/dev/null || err_exit "Xcode Command Line Tools not found. Run: xcode-select --install"
xcrun swift --version &>/dev/null || err_exit "Swift not found. Make sure Xcode 16+ is installed."

# ── 2. Install Homebrew if missing ───────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  info "Homebrew already installed: $(brew --version | head -1)"
fi

# ── 3. Install XcodeGen ──────────────────────────────────────
if ! command -v xcodegen &>/dev/null; then
  info "Installing XcodeGen…"
  brew install xcodegen
else
  info "XcodeGen already installed: $(xcodegen --version 2>&1 | head -1)"
fi

# ── 4. Confirm project.yml exists ────────────────────────────
[[ -f "$REPO_DIR/project.yml" ]] || err_exit "project.yml not found in $REPO_DIR"

# ── 5. Generate the .xcodeproj ───────────────────────────────
info "Generating Biblically.xcodeproj…"
xcodegen generate --spec "$REPO_DIR/project.yml" --project "$REPO_DIR"
info "✓ Biblically.xcodeproj created"

# ── 6. Print next steps ──────────────────────────────────────
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Project generated successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps — run these commands:"
echo ""
echo "  1. Find your connected device UDID:"
echo "     xcrun devicectl list devices"
echo ""
echo "  2. Set your Team ID in project.yml (line: DEVELOPMENT_TEAM: \"\")"
echo "     then re-run:  ./setup.sh"
echo ""
echo "  3. Build the app (replace DEVICE_UDID with your actual UDID):"
echo "     xcodebuild \\"
echo "       -project Biblically.xcodeproj \\"
echo "       -scheme Biblically \\"
echo "       -destination 'platform=iOS,id=DEVICE_UDID' \\"
echo "       -configuration Debug \\"
echo "       build"
echo ""
echo "  4. Install on device:"
echo "     xcrun devicectl device install app \\"
echo "       --device DEVICE_UDID \\"
echo "       /path/to/derived/Biblically.app"
echo ""
echo "  Or just open in Xcode and press ▶:"
echo "     open Biblically.xcodeproj"
echo ""
