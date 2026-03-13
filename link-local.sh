#!/bin/bash
# ============================================================
# Link Local ZecKit Setup
# ============================================================
# This script creates a symlink from your local ZecKit folder
# to .zeckit-action, enabling "dual-linkage".
#
# When this link exists:
#   1. Local tests (test-local.sh) use your local files.
#   2. Local workflow runs (via act) use your local files.
#
# When this link is missing (e.g. on GitHub CI):
#   1. The workflow pulls ZecKit from the remote repository.
# ============================================================

ZECKIT_SOURCE="../ZecKit"
LINK_NAME=".zeckit-action"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ZecKit Local Linker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Check if source exists
if [ ! -d "$ZECKIT_SOURCE" ]; then
    echo ":: Error: Source project not found at $ZECKIT_SOURCE"
    exit 1
fi

# 2. Handle existing link/folder
if [ -e "$LINK_NAME" ] || [ -L "$LINK_NAME" ]; then
    echo ":: Removing existing $LINK_NAME..."
    rm -rf "$LINK_NAME"
fi

# 3. Create symlink
echo ":: Linking $ZECKIT_SOURCE -> $LINK_NAME"
ln -s "$ZECKIT_SOURCE" "$LINK_NAME"

echo ":: OK! Local linkage activated."
echo "   Run ./test-local.sh to verify."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
