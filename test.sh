#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create a temporary test directory
TEST_DIR=$(mktemp -d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Setting up test environment in: $TEST_DIR"
echo "📍 Using script from: $SCRIPT_DIR"

trap "rm -rf $TEST_DIR" EXIT

cd "$TEST_DIR"

# Copy the script to test directory
cp "$SCRIPT_DIR/check_migration_timestamp.sh" .

# Initialize git repo
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Create directory structure
mkdir -p src/models src/migrations

# Create initial files and commit
echo "# Models" > src/models/base.py
echo "# Migration base" > src/migrations/__init__.py
git add .
git commit -m "Initial commit"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\n${YELLOW}Test 1: No changes (should pass)${NC}"
bash check_migration_timestamp.sh \
  --model-dirs=src/models \
  --migration-dir=src/migrations \
  --exclude=__init__.py && echo -e "${GREEN}✅ PASS${NC}" || echo -e "${RED}❌ FAIL${NC}"

echo -e "\n${YELLOW}Test 2: Model change without migration (should fail)${NC}"
echo "class User: pass" > src/models/user.py
git add src/models/user.py
bash check_migration_timestamp.sh \
  --model-dirs=src/models \
  --migration-dir=src/migrations \
  --exclude=__init__.py && echo -e "${RED}❌ FAIL - Should have failed${NC}" || echo -e "${GREEN}✅ PASS - Correctly failed${NC}"

echo -e "\n${YELLOW}Test 3: Model change with migration (should pass)${NC}"
echo "def upgrade(): pass" > src/migrations/001_add_user.py
git add src/migrations/001_add_user.py
bash check_migration_timestamp.sh \
  --model-dirs=src/models \
  --migration-dir=src/migrations \
  --exclude=__init__.py && echo -e "${GREEN}✅ PASS${NC}" || echo -e "${RED}❌ FAIL${NC}"

echo -e "\n${YELLOW}Test 4: Multiple model dirs with excludes (should pass)${NC}"
git commit -m "Add user model and migration"
mkdir -p src/entities
echo "class Entity: pass" > src/entities/base.py
git add src/entities/base.py
git commit -m "Add entities"

echo "class Post: pass" > src/entities/post.py
git add src/entities/post.py
echo "def upgrade(): pass" > src/migrations/002_add_post.py
git add src/migrations/002_add_post.py
bash check_migration_timestamp.sh \
  --model-dirs=src/models,src/entities \
  --migration-dir=src/migrations \
  --exclude=__init__.py,base.py && echo -e "${GREEN}✅ PASS${NC}" || echo -e "${RED}❌ FAIL${NC}"

echo -e "\n${YELLOW}Test 5: Changes only in excluded files (should pass)${NC}"
git commit -m "Add post model and migration"
echo "# Updated base" >> src/models/base.py
git add src/models/base.py
bash check_migration_timestamp.sh \
  --model-dirs=src/models \
  --migration-dir=src/migrations \
  --exclude=__init__.py,base.py && echo -e "${GREEN}✅ PASS${NC}" || echo -e "${RED}❌ FAIL${NC}"

echo -e "\n${GREEN}✅ All tests completed!${NC}"
