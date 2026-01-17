# check_migration

A git pre-commit hook that ensures database model and entity changes are always accompanied by a new Alembic migration.

## Problem

When working with database models in a project using Alembic for migrations, it's easy to forget to create a migration after modifying model files. This hook automatically detects such cases and prevents commits with unmigrated changes.

The hook uses **git staging information** to check only the files you're actually committing, preventing false positives from other pre-commit hooks (like `ruff`, `black`, etc.) that might modify files.

## Installation

Add this to your `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/risclog-solution/check_migration
    rev: v0.2.0
    hooks:
      - id: check-model-vs-migration
        name: Check database models have migrations
        language: script
        args: [
          "--model-dirs=src/myapp/database,src/myapp/entities",
          "--migration-dir=src/myapp/alembic/versions",
          "--exclude=__init__.py,base.py,README.md",
          "--exclude-dir=__pycache__,.mypy_cache,.pytest_cache,.git"
        ]
        stages: [manual]
```

## Configuration

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--model-dirs` | Yes | Comma-separated list of directories containing model/entity files |
| `--migration-dir` | Yes | Directory where Alembic migration files are stored |
| `--exclude` | No | Comma-separated list of filenames to exclude from checks |
| `--exclude-dir` | No | Comma-separated list of directory names to exclude |

### Examples

**Basic setup:**

```yaml
args: [
  "--model-dirs=src/models",
  "--migration-dir=src/migrations"
]
```

**Multiple model directories:**

```yaml
args: [
  "--model-dirs=src/database,src/entities,src/schemas",
  "--migration-dir=src/alembic/versions",
  "--exclude=__init__.py,base.py"
]
```

## How It Works

1. Reads all files staged for commit using `git diff --cached`
2. Checks if any files in `--model-dirs` have been modified
3. Filters out excluded files (specified with `--exclude`)
4. If model changes exist, verifies that at least one migration file exists in `--migration-dir`
5. Fails with error message if migrations are missing

## Behavior

### Passes

- No model files were changed
- Model files were changed AND migration file was staged
- Only excluded files were changed

### Fails

- Model files were changed but no migration file was staged
- Shows which model files were modified
- Suggests using `alembic revision --autogenerate -m '...'`

## Usage in Development

By default, the hook runs in `stages: [manual]`, so you must explicitly run it:

```bash
# Run the check manually
pre-commit run check-model-vs-migration --all-files

# Run all manual-stage hooks
pre-commit run --hook-stage manual --all-files
```

## Testing

Run the included test suite:

```bash
bash test.sh
```

This executes 5 comprehensive tests covering all scenarios.

## Why Git-Based Instead of Timestamps?

Earlier versions used filesystem timestamps, which caused false positives. Other pre-commit hooks like `ruff`, `ruff-format`, and `pyupgrade` modify files, updating their timestamps even without functional changes. The new version uses `git diff --cached` to only check files you're actually committing, providing accurate, reliable detection.
