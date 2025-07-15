# check_migration

Pre-commit hook to ensure database database/entitities changes are always accompanied by a new Alembic migration.

## Usage

```yaml
repos:
  - repo: https://github.com/risclog-solution/check_migration
    rev: v0.1.0
    hooks:
      - id: check-model-vs-migration
        args: [
          "--model-dirs=src/risclog/claimxdb/database,src/risclog/claimxdb/entities",
          "--migration-dir=src/risclog/claimxdb/alembic/versions",
          "--exclude=__init__.py,README.md,base.py",
          "--exclude-dir=__pycache__,.mypy_cache,.pytest_cache,.git"
        ]
