#!/usr/bin/env bash
set -euo pipefail

branch="main"
dry_run="0"

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      dry_run="1"
      ;;
    --branch=*)
      branch="${arg#*=}"
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: bash scripts/sync-downstream.sh [--branch=<name>] [--dry-run]"
      exit 1
      ;;
  esac
done

run() {
  if [[ "$dry_run" == "1" ]]; then
    echo "+ $*"
    return 0
  fi
  "$@"
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is not clean. Commit/stash/discard changes before downstream sync."
  exit 1
fi

run git fetch origin
run git fetch fork

if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  echo "Remote branch origin/$branch does not exist."
  exit 1
fi

run git checkout "$branch"
run git reset --hard "origin/$branch"
run git push --force-with-lease fork "$branch"
run git status --short --branch

echo "Downstream sync complete: local $branch and fork/$branch now match origin/$branch."
