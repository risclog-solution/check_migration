#!/usr/bin/env bash
set -euo pipefail

MODEL_DIRS="" 
MIGRATION_DIR="" 

for arg in "$@"; do
    case $arg in
        --model-dirs=*) MODEL_DIRS="${arg#*=}" ;;
        --migration-dir=*) MIGRATION_DIR="${arg#*=}" ;;
        *) echo "Unknown parameter: $arg"; exit 1 ;;
    esac
done

[ -z "$MODEL_DIRS" ] || [ -z "$MIGRATION_DIR" ] && {
    echo "❌ Error: --model-dirs and --migration-dir must be set." 
    exit 1
}

IFS=',' read -ra DIRS <<< "$MODEL_DIRS" 
latest_model_change=0

for dir in "${DIRS[@]}"; do
    [ -d "$dir" ] && {
        ts=$(find "$dir" -type f -exec stat -c "%Y" {} + | sort -n | tail -n 1 || echo 0)
        (( ts > latest_model_change )) && latest_model_change=$ts
    }
done

if [ -d "$MIGRATION_DIR" ]; then
    latest_migration_change=$(find "$MIGRATION_DIR" -type f -name "*.py" -exec stat -c "%Y" {} + | sort -n | tail -n 1 || echo 0)
else
    latest_migration_change=0
fi

if (( latest_model_change > latest_migration_change )); then
    echo "❌ Detected changes in model/entity directories without a newer migration in $MIGRATION_DIR" 
    echo "→ Please create a migration using: alembic revision --autogenerate -m '...'" 
    exit 1
fi

exit 0