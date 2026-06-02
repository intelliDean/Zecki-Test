#!/bin/bash
# ============================================================
# Local Test Script for ZecKit Sample Repo
# ============================================================
# This script runs the ZecKit E2E suite using the local
# ZecKit project at /mnt/data/Projects/ZecKit.
# ============================================================

set -e

# Detect ZecKit CLI
if [ -d "../cli" ] || [ -d "../ZecKit" ]; then
    if [ -d "../cli" ]; then
        ZECKIT_SRC_PATH=".."
    else
        ZECKIT_SRC_PATH="../ZecKit"
    fi
    if [ -f "$ZECKIT_SRC_PATH/target/release/zeckit" ]; then
        ZECKIT_EXE="$ZECKIT_SRC_PATH/target/release/zeckit"
    elif [ -f "$ZECKIT_SRC_PATH/cli/target/release/zeckit" ]; then
        ZECKIT_EXE="$ZECKIT_SRC_PATH/cli/target/release/zeckit"
    else
        ZECKIT_EXE="$ZECKIT_SRC_PATH/target/release/zeckit"
    fi
    echo ":: Local source detected at $ZECKIT_SRC_PATH. Using $ZECKIT_EXE"
elif command -v zeckit >/dev/null 2>&1; then
    ZECKIT_EXE="zeckit"
    echo ":: Using system 'zeckit' from PATH"
else
    echo "❌ Error: 'zeckit' CLI not found in PATH or relative source dirs"
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
    (cd "$ZECKIT_SRC_PATH" && cargo build --release)
    # Ensure the detected EXE path exists/is updated
    if [ -f "$ZECKIT_SRC_PATH/target/release/zeckit" ]; then
        ZECKIT_EXE="$ZECKIT_SRC_PATH/target/release/zeckit"
    fi
else
    echo ":: Skipping CLI build (Using pre-installed binary)"
fi

# 3. Start services with a clean state
echo ":: Purging old devnet state..."
"$ZECKIT_EXE" down --purge

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Testing Custom Block Interval"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ":: Starting devnet with 5s block interval..."
"$ZECKIT_EXE" up --backend "$BACKEND" --block-interval 5

echo ":: Verifying block generation rate..."
INITIAL_HEIGHT=$(curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' http://127.0.0.1:8232 | jq .result)
echo "   Initial Height: $INITIAL_HEIGHT"
sleep 15
NEW_HEIGHT=$(curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' http://127.0.0.1:8232 | jq .result)
echo "   New Height: $NEW_HEIGHT"
if [ "$NEW_HEIGHT" -le "$INITIAL_HEIGHT" ]; then
    echo "❌ Error: Block height did not increase with --block-interval 5"
    exit 1
fi
echo "✓ Verified custom block interval works!"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Testing Snapshot & Restore Lifecycle"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ":: Creating snapshot 'sample-local-snap'..."
"$ZECKIT_EXE" snapshot create sample-local-snap

echo ":: Verifying snapshot exists in list..."
if ! "$ZECKIT_EXE" snapshot list | grep -q "sample-local-snap"; then
    echo "❌ Error: snapshot list does not contain 'sample-local-snap'"
    exit 1
fi
echo "✓ Snapshot listed successfully"

echo ":: Wiping current devnet state..."
"$ZECKIT_EXE" down --purge

echo ":: Starting clean devnet (back to genesis)..."
"$ZECKIT_EXE" up --backend "$BACKEND"
CLEAN_HEIGHT=$(curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' http://127.0.0.1:8232 | jq .result)
echo "   Clean Height: $CLEAN_HEIGHT"

echo ":: Restoring snapshot..."
"$ZECKIT_EXE" snapshot restore sample-local-snap

echo ":: Restarting devnet from restored state..."
"$ZECKIT_EXE" up --backend "$BACKEND"
RESTORED_HEIGHT=$(curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' http://127.0.0.1:8232 | jq .result)
echo "   Restored Height: $RESTORED_HEIGHT"

if [ "$RESTORED_HEIGHT" -lt "$NEW_HEIGHT" ]; then
    echo "❌ Error: Restored height ($RESTORED_HEIGHT) is less than snapshotted height ($NEW_HEIGHT)"
    exit 1
fi
echo "✓ Verified snapshot restore successfully recovered state!"

echo ":: Deleting snapshot..."
"$ZECKIT_EXE" snapshot delete sample-local-snap
echo "✓ Snapshot deleted successfully"
echo ""

# 4. Run tests (ZecKit Internal)
echo ":: Running ZecKit Internal E2E tests..."
if ! "$ZECKIT_EXE" test; then
    echo ":: Error: Internal tests failed. Inspecting logs..."
    docker ps
    echo ":: Faucet Logs (last 50 lines):"
    docker logs zeckit-faucet-"$BACKEND"-1 | tail -n 50
    echo ":: Backend Logs (last 50 lines):"
    docker logs zeckit-"$BACKEND"-1 | tail -n 50
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
