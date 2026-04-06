#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${root_dir}"

source "${root_dir}/scripts/lib/lex0-release.sh"

payload_file="${1:-}"
open_pr="${2:-false}"

if [ -z "${payload_file}" ] || [ ! -f "${payload_file}" ]; then
  echo "Usage: $0 <payload-json-file> [open-pr:true|false]" >&2
  exit 1
fi

require_clean_worktree

source_repo=$(jq -r '.source_repo // empty' "${payload_file}")
tag=$(jq -r '.tag // empty' "${payload_file}")
schema_version=$(jq -r '.schema_version // empty' "${payload_file}")
release_url=$(jq -r '.release_url // empty' "${payload_file}")
commit_sha=$(jq -r '.commit_sha // empty' "${payload_file}")
rng_url=$(jq -r '.assets.rng_url // empty' "${payload_file}")
rnc_url=$(jq -r '.assets.rnc_url // empty' "${payload_file}")
xsd_url=$(jq -r '.assets.xsd_url // empty' "${payload_file}")

if [ "${source_repo}" != "BCDH/tei-lex-0" ]; then
  echo "Unexpected source_repo: ${source_repo}" >&2
  exit 1
fi

if ! [[ "${schema_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid schema_version: ${schema_version}" >&2
  exit 1
fi

if [ "${tag}" != "v${schema_version}" ]; then
  echo "Tag ${tag} does not match schema_version ${schema_version}" >&2
  exit 1
fi

if ! semver_ge "${schema_version}" "0.9.5"; then
  echo "Unsupported schema_version ${schema_version}; automation starts at 0.9.5." >&2
  exit 1
fi

if [ -z "${release_url}" ] || [ -z "${commit_sha}" ] || [ -z "${rng_url}" ]; then
  echo "Payload is missing release_url, commit_sha, or assets.rng_url." >&2
  exit 1
fi

if ! validate_url_basename "${rng_url}" "lex-0.rng"; then
  echo "Unsupported RNG asset basename: ${rng_url}" >&2
  exit 1
fi

if [ -n "${rnc_url}" ] && ! validate_url_basename "${rnc_url}" "lex-0.rnc"; then
  echo "Unsupported RNC asset basename: ${rnc_url}" >&2
  exit 1
fi

if [ -n "${xsd_url}" ] && ! validate_url_basename "${xsd_url}" "lex-0.xsd"; then
  echo "Unsupported XSD asset basename: ${xsd_url}" >&2
  exit 1
fi

branch_name="automation/lex0-v${schema_version}"
schema_dir="src/schemas/${schema_version}"

if [ -d "${schema_dir}" ]; then
  echo "Schema directory already exists: ${schema_dir}" >&2
  exit 1
fi

if [ "$(framework_schema_version)" = "${schema_version}" ]; then
  echo "framework.xml already references schema_version ${schema_version}" >&2
  exit 1
fi

if remote_branch_exists "${branch_name}"; then
  echo "Remote branch already exists: ${branch_name}" >&2
  exit 1
fi

if open_pr_exists_for_branch "${branch_name}"; then
  echo "Open PR already exists for branch ${branch_name}" >&2
  exit 1
fi

git fetch origin dev
git checkout -B dev origin/dev
git switch -c "${branch_name}"

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${schema_dir}"
curl -fsSL "${rng_url}" -o "${schema_dir}/lex-0.rng"
if [ -n "${rnc_url}" ]; then
  curl -fsSL "${rnc_url}" -o "${schema_dir}/lex-0.rnc"
fi
if [ -n "${xsd_url}" ]; then
  curl -fsSL "${xsd_url}" -o "${schema_dir}/lex-0.xsd"
fi

for required_file in "${schema_dir}/lex-0.rng"; do
  if [ ! -s "${required_file}" ]; then
    echo "Downloaded file is missing or empty: ${required_file}" >&2
    exit 1
  fi
done

current_version=$(framework_value version)
current_schema_version=$(framework_schema_version)
next_version=$(next_framework_version "${current_version}")
set_framework_versions "${schema_version}" "${next_version}"

ant -f build.xml add-schema-version add-version-to-web

cp "build/${schema_version}/src/teilex0.exf" "src/teilex0.exf"
cp "build/${schema_version}/src/teilex0.framework" "src/teilex0.framework"
cp "build/${schema_version}/src/resources/validation.scenarios" "src/resources/validation.scenarios"
cp "build/${schema_version}/web/addon.xml" "web/addon.xml"

./scripts/build-package.sh

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git add framework.xml \
  src/catalog.xml \
  src/teilex0.exf \
  src/teilex0.framework \
  src/resources/validation.scenarios \
  "${schema_dir}" \
  web/addon.xml

if git diff --cached --quiet; then
  echo "No changes produced for ${schema_version}" >&2
  exit 1
fi

git commit -m "chore: integrate TEI Lex-0 v${schema_version}"
git push -u origin "${branch_name}"

if [ "${open_pr}" = "true" ]; then
  pr_body_file="${tmp_dir}/pr-body.md"
  {
    printf 'Upstream release: %s\n\n' "${release_url}"
    printf 'Upstream tag: `%s`\n' "${tag}"
    printf 'Upstream commit: `%s`\n\n' "${commit_sha}"
    printf 'Framework version: `%s` -> `%s`\n' "${current_version}" "${next_version}"
    printf 'Schema version: `%s` -> `%s`\n\n' "${current_schema_version}" "${schema_version}"
    printf 'Imported assets:\n'
    printf -- '- `%s`\n' "$(basename "${rng_url}")"
    [ -n "${rnc_url}" ] && printf -- '- `%s`\n' "$(basename "${rnc_url}")"
    [ -n "${xsd_url}" ] && printf -- '- `%s`\n' "$(basename "${xsd_url}")"
    if [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ] && [ -n "${GITHUB_RUN_ID:-}" ]; then
      printf '\nAutomation run: %s/%s/actions/runs/%s\n' "${GITHUB_SERVER_URL}" "${GITHUB_REPOSITORY}" "${GITHUB_RUN_ID}"
    fi
  } > "${pr_body_file}"

  pr_url=$(gh pr create \
    --base dev \
    --head "${branch_name}" \
    --title "chore: integrate TEI Lex-0 v${schema_version}" \
    --body-file "${pr_body_file}")
  printf 'pr_url=%s\n' "${pr_url}" >> "${GITHUB_OUTPUT:-/dev/null}"
fi

printf 'branch_name=%s\n' "${branch_name}" >> "${GITHUB_OUTPUT:-/dev/null}"
printf 'schema_version=%s\n' "${schema_version}" >> "${GITHUB_OUTPUT:-/dev/null}"
