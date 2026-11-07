#!/usr/bin/env bash
# Convenience publishing script. Needs git, GitHub CLI (gh), and gh auth login.
# Run from an extracted copy: bash publish_to_github.sh
set -euo pipefail
cd "$(dirname "$0")"
if ! command -v git >/dev/null || ! command -v gh >/dev/null; then
  echo 'Please install git + GitHub CLI (gh) first.' >&2
  exit 1
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init -b main
fi
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git add .
  git -c user.name='Mangal Evening Generator' -c user.email='mangal-generator@local.invalid' commit -m 'Initial Godot BBQ pixel-art game'
fi
gh auth status >/dev/null || { echo 'First run: gh auth login'; exit 1; }
gh repo create mangal-tihiy-vecher --public --source=. --remote=origin --push
