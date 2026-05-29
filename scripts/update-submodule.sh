#!/bin/bash
# Update the ninja submodule and remind to re-check docs.
set -e

COMMIT="${1}"
if [ -z "$COMMIT" ]; then
    echo "Usage: $0 <commit-hash-or-tag>"
    echo "Example: $0 v1.12.1"
    exit 1
fi

echo "Updating ninja submodule to $COMMIT..."

cd "$(dirname "$0")/.."
cd ninja
git fetch origin
git checkout "$COMMIT"
cd ..

echo ""
echo "ninja submodule updated to:"
git -C ninja log -1 --oneline
echo ""
echo "Remember to:"
echo "  1. Diff the changed files: git -C ninja diff <old-commit>..<new-commit>"
echo "  2. Re-check and update affected docs in docs/ (line numbers!)"
echo "  3. Update the pinned commit in docs/_config.yml (source_rewrite.base)"
echo "  4. Commit both the submodule pointer and doc updates"
