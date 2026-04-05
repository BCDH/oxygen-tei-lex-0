#!/usr/bin/env bash

set -euo pipefail

site_dir="${1:-}"
target_branch="${2:-gh-pages}"
target_repository="${3:-${GITHUB_REPOSITORY:-}}"

if [ -z "${site_dir}" ]; then
  echo "Usage: $0 <site-dir> [target-branch] [target-repository]" >&2
  exit 1
fi

if [ ! -d "${site_dir}" ]; then
  echo "Site directory does not exist: ${site_dir}" >&2
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Missing GITHUB_TOKEN for publishing ${target_repository}" >&2
  exit 1
fi

if [ -z "${target_repository}" ]; then
  echo "Missing target repository. Set GITHUB_REPOSITORY or pass it explicitly." >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

worktree_dir="${tmp_dir}/repo"
remote_url="https://x-access-token:${GITHUB_TOKEN}@github.com/${target_repository}.git"

git init "${worktree_dir}" >/dev/null 2>&1
cd "${worktree_dir}"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add origin "${remote_url}"

if git fetch --depth=1 origin "${target_branch}" >/dev/null 2>&1; then
  git checkout -B "${target_branch}" FETCH_HEAD >/dev/null 2>&1
else
  git checkout --orphan "${target_branch}" >/dev/null 2>&1
fi

find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -R "${site_dir}"/. .

git add --all

if git diff --cached --quiet; then
  printf 'No site changes to publish to %s:%s\n' "${target_repository}" "${target_branch}"
  exit 0
fi

git commit -m "Deploy static site from ${GITHUB_REPOSITORY:-local} ${GITHUB_SHA:-manual}" >/dev/null 2>&1
git push --force-with-lease origin "${target_branch}" >/dev/null 2>&1

printf 'Published %s to %s:%s\n' "${site_dir}" "${target_repository}" "${target_branch}"
