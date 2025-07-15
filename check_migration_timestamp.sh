#!/usr/bin/env bash
set -euo pipefail

MODEL_DIRS=""
MIGRATION_DIR=""
EXCLUDES=()
EXCLUDE_DIRS=()


for arg in "$@"; do
    case $arg in
        --model-dirs=*) MODEL_DIRS="${arg#*=}" ;;
        --migration-dir=*) MIGRATION_DIR="${arg#*=}" ;;
        --exclude=*) IFS=',' read -ra EXC <<< "${arg#*=}"; EXCLUDES+=("${EXC[@]}") ;;
        --exclude-dir=*) IFS=',' read -ra EXC_DIR <<< "${arg#*=}"; EXCLUDE_DIRS+=("${EXC_DIR[@]}") ;;
        *) ;;  
    esac
done

if [[ -z "$MODEL_DIRS" || -z "$MIGRATION_DIR" ]]; then
    echo "❌ Error: --model-dirs and --migration-dir must be set."
    exit 1
fi

IFS=',' read -ra DIRS <<< "$MODEL_DIRS"
latest_model_change=0

FIND_EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
    FIND_EXCLUDE_ARGS+=(! -name "$pattern")
done

FIND_PRUNE_ARGS=()
for d in "${EXCLUDE_DIRS[@]}"; do
    FIND_PRUNE_ARGS+=( -name "$d" -prune -o )
done

any_file_found=false
for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        ts=$(find "$dir" "${FIND_PRUNE_ARGS[@]}" -type f "${FIND_EXCLUDE_ARGS[@]}" \
            -exec stat -c "%Y" {} + 2>/dev/null | sort -n | tail -n 1 || echo "")
        if [ -n "$ts" ]; then
            any_file_found=true
            if [ "$ts" -gt "$latest_model_change" ]; then
                latest_model_change=$ts
            fi
        fi
    fi
done

if [ "$any_file_found" = false ]; then
    exit 0
fi

if [ -d "$MIGRATION_DIR" ]; then
    latest_migration_change=$(find "$MIGRATION_DIR" -type f -name "*.py" \
        -exec stat -c "%Y" {} + 2>/dev/null | sort -n | tail -n 1 || echo 0)
    latest_migration_change="${latest_migration_change:-0}"
else
    latest_migration_change=0
fi

if (( latest_model_change > latest_migration_change )); then
    echo "❌ Detected changes in database/entitities directories without a newer migration in $MIGRATION_DIR"
    echo "→ Please create a migration using: alembic revision --autogenerate -m '...'"
    exit 1
fi

exit 0
