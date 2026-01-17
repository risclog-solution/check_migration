#!/usr/bin/env bash
set -euo pipefail

MODEL_DIRS=""
MIGRATION_DIR=""
EXCLUDES=()

for arg in "$@"; do
    case $arg in
        --model-dirs=*) MODEL_DIRS="${arg#*=}" ;;
        --migration-dir=*) MIGRATION_DIR="${arg#*=}" ;;
        --exclude=*) IFS=',' read -ra EXC <<< "${arg#*=}"; EXCLUDES+=("${EXC[@]}") ;;
        --exclude-dir=*) ;; # ignored for now, kept for compatibility
        *) ;;  
    esac
done

if [[ -z "$MODEL_DIRS" || -z "$MIGRATION_DIR" ]]; then
    echo "❌ Error: --model-dirs and --migration-dir must be set."
    exit 1
fi

# Get staged files
STAGED_FILES=$(git diff --cached --name-only)

# Build exclude pattern
EXCLUDE_PATTERN=""
for pattern in "${EXCLUDES[@]}"; do
    if [ -n "$EXCLUDE_PATTERN" ]; then
        EXCLUDE_PATTERN="$EXCLUDE_PATTERN|$pattern"
    else
        EXCLUDE_PATTERN="$pattern"
    fi
done

# Check for changed model files in staging area
MODEL_CHANGES=""
IFS=',' read -ra DIRS <<< "$MODEL_DIRS"

for dir in "${DIRS[@]}"; do
    dir_changes=$(echo "$STAGED_FILES" | grep "^$dir/" || true)
    if [ -n "$dir_changes" ]; then
        if [ -n "$EXCLUDE_PATTERN" ]; then
            dir_changes=$(echo "$dir_changes" | grep -v -E "$EXCLUDE_PATTERN" || true)
        fi
        if [ -n "$dir_changes" ]; then
            MODEL_CHANGES="$dir_changes"
            break
        fi
    fi
done

# If no model changes, we're good
if [ -z "$MODEL_CHANGES" ]; then
    exit 0
fi

# Check for migration changes in staging area
MIGRATION_CHANGES=$(echo "$STAGED_FILES" | grep "^$MIGRATION_DIR/" | grep "\.py$" || true)

if [ -z "$MIGRATION_CHANGES" ]; then
    echo "❌ Detected changes in $(echo "$MODEL_DIRS" | tr ',' ' + ') without a new migration in $MIGRATION_DIR"
    echo ""
    echo "Changed model files:"
    echo "$MODEL_CHANGES"
    echo ""
    echo "→ Please create a migration using: alembic revision --autogenerate -m '...'"
    exit 1
fi

exit 0
