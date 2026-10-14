#!/usr/bin/env bash
# ============================================================================
# Chapter 07 Lab: Git Workflow & Conventional Commits Demonstration
# ============================================================================

set -e

LAB_DIR="labs/devops/git_sandbox"

echo "🚀 Setting up local Git lab sandbox in: ${LAB_DIR}"
rm -rf "${LAB_DIR}"
mkdir -p "${LAB_DIR}"
cd "${LAB_DIR}"#!/usr/bin/env bash
# ============================================================================
# Chapter 07 Lab: Git Workflow & Conventional Commits Demonstration
# ============================================================================

set -e

LAB_DIR="labs/devops/git_sandbox"

echo "🚀 Setting up local Git lab sandbox in: ${LAB_DIR}"
rm -rf "${LAB_DIR}"
mkdir -p "${LAB_DIR}"
cd "${LAB_DIR}"

# 1. Initialize Repository and Configure Local Identity
git init -b main
git config user.name "Handbook Dev"
git config user.email "dev@example.com"

# 2. Initial Setup Commit
echo "# Git Workflow Sandbox" > README.md
git add README.md
git commit -m "chore(repo): initialize project sandbox"

# 3. Feature Development on Branch
git switch -c feature/user-auth

echo 'export const login = () => "user logged in";' > auth.js
git add auth.js
git commit -m "feat(auth): implement initial login function"

echo 'export const logout = () => "user logged out";' >> auth.js
git add auth.js
git commit -m "feat(auth): add logout handling"

echo '// TODO: Add refresh token logic' >> auth.js
git add auth.js
git commit -m "docs(auth): document refresh token requirement"

# 4. Display History Before Rebase/Squash
echo ""
echo "📜 Commit History on 'feature/user-auth' before squash:"
git log --oneline -n 3

# 5. Non-interactive Rebase (Squashing last 2 commits into one clean commit)
git reset --soft HEAD~2
git commit -m "feat(auth): support user authentication with logout"

echo ""
echo "✨ Cleaned Commit History after squashing:"
git log --oneline -n 2

# 6. Merge back to Main Branch
git switch main
git merge --no-ff feature/user-auth -m "merge(auth): integrate feature/user-auth into main"

echo ""
echo "🎉 Final Linear Repository History on main:"
git log --oneline --graph --all

# Cleanup sandbox files
cd ../../..
rm -rf "${LAB_DIR}"
echo ""
echo "✅ Lab 07 demonstration complete and cleaned up!"

# 1. Initialize Repository and Configure Local Identity
git init -b main
git config user.name "Handbook Dev"
git config user.email "dev@example.com"

# 2. Initial Setup Commit
echo "# Git Workflow Sandbox" > README.md
git add README.md
git commit -m "chore(repo): initialize project sandbox"

# 3. Feature Development on Branch
git switch -c feature/user-auth

echo 'export const login = () => "user logged in";' > auth.js
git add auth.js
git commit -m "feat(auth): implement initial login function"

echo 'export const logout = () => "user logged out";' >> auth.js
git add auth.js
git commit -m "feat(auth): add logout handling"

echo '// TODO: Add refresh token logic' >> auth.js
git add auth.js
git commit -m "docs(auth): document refresh token requirement"

# 4. Display History Before Rebase/Squash
echo ""
echo "📜 Commit History on 'feature/user-auth' before squash:"
git log --oneline -n 3

# 5. Non-interactive Rebase (Squashing last 2 commits into one clean commit)
git reset --soft HEAD~2
git commit -m "feat(auth): support user authentication with logout"

echo ""
echo "✨ Cleaned Commit History after squashing:"
git log --oneline -n 2

# 6. Merge back to Main Branch
git switch main
git merge --no-ff feature/user-auth -m "merge(auth): integrate feature/user-auth into main"

echo ""
echo "🎉 Final Linear Repository History on main:"
git log --oneline --graph --all

# Cleanup sandbox files
cd ../../..
rm -rf "${LAB_DIR}"
echo ""
echo "✅ Lab 07 demonstration complete and cleaned up!"
