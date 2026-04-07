#!/bin/bash
# ============================================================
# Local Test Script for ZecKit Sample Repo
# ============================================================
# This script runs the ZecKit E2E suite using the local
# ZecKit project at /mnt/data/Projects/ZecKit.
# ============================================================

set -e

# Detect ZecKit CLI
if command -v zeckit >/dev/null 2>&1; then
    ZECKIT_EXE="zeckit"
    echo ":: Using system 'zeckit' from PATH"
elif [ -f "../ZecKit/cli/target/release/zeckit" ]; then
    ZECKIT_EXE="../ZecKit/cli/target/release/zeckit"
    ZECKIT_SRC_PATH="../ZecKit"
    echo ":: Using local 'ZecKit' build at $ZECKIT_EXE"
else
    echo "❌ Error: 'zeckit' CLI not found in PATH or ../ZecKit"
    echo ""
    echo "Please install it via: cargo install zeckit"
    echo "Or build it locally: cd ../ZecKit/cli && cargo build --release"
    exit 1
fi

BACKEND=${1:-zaino}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ZecKit Local Test Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Project Path : $ZECKIT_PATH"
echo "  Backend      : $BACKEND"

# 2. Rebuild Components (Enforce latest fixes)
# NOTE: Skipping Docker build as images already exist and network might be restricted.
# echo ":: Rebuilding Faucet image..."
# (cd "$ZECKIT_PATH" && docker compose build faucet-zaino)

if [ -n "$ZECKIT_SRC_PATH" ]; then
    echo ":: Rebuilding ZecKit CLI (Source detected)..."
    (cd "$ZECKIT_SRC_PATH/cli" && cargo build --release)
else
    echo ":: Skipping CLI build (Using pre-installed binary)"
fi

# 3. Start services with a clean state
echo ":: Purging old devnet state..."
"$ZECKIT_EXE" down --purge

echo ":: Starting devnet..."
"$ZECKIT_EXE" up --backend "$BACKEND"

# 3. Clean up on exit (Commented out for debugging)
# trap '"$ZECKIT_EXE" --project-dir "$ZECKIT_PATH" down' EXIT

# 4. Run tests (ZecKit Internal)
echo ":: Running ZecKit Internal E2E tests..."
if ! "$ZECKIT_EXE" test; then
    echo ":: Error: Internal tests failed. Inspecting logs..."
    docker ps
    echo ":: Faucet Logs (last 50 lines):"
    docker logs zeckit-faucet-zaino-1 | tail -n 50
    echo ":: Zaino Logs (last 50 lines):"
    docker logs zeckit-zaino-1 | tail -n 50
    exit 1
fi

# 5. Run Example App Verification
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Integrated Application Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "example-app" ]; then
    echo ":: 1. Installing app dependencies..."
    (cd example-app && npm install)
    
    echo ":: 2. Executing Example App (Safe Send)..."
    (cd example-app && npm start)
else
    echo ":: Warning: example-app directory not found, skipping app verification."
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Local Test Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
