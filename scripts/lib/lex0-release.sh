#!/usr/bin/env bash

set -euo pipefail

semver_ge() {
  local left right
  left=$(printf '%s\n' "$1" | awk -F. '{ printf "%d%03d%03d\n", $1, $2, $3 }')
  right=$(printf '%s\n' "$2" | awk -F. '{ printf "%d%03d%03d\n", $1, $2, $3 }')
  [ "${left}" -ge "${right}" ]
}

require_clean_worktree() {
  git diff --quiet
  git diff --cached --quiet
}

validate_url_basename() {
  local url expected
  url="$1"
  expected="$2"
  [ "$(basename "${url}")" = "${expected}" ]
}

framework_value() {
  local field
  field="$1"
  awk -F'[<>]' -v wanted="${field}" '$2 == wanted { print $3; exit }' framework.xml
}

framework_schema_version() {
  awk -F'[<>]' '
    $2 ~ /^schema([[:space:]]|$)/ { in_schema = 1; next }
    in_schema && $2 == "version" { print $3; exit }
  ' framework.xml
}

next_framework_version() {
  awk -F. '{ printf "%d.%d.0\n", $1, $2 + 1 }' <<<"$1"
}

remote_branch_exists() {
  git ls-remote --exit-code --heads origin "$1" >/dev/null 2>&1
}

open_pr_exists_for_branch() {
  local branch count
  branch="$1"
  count=$(gh pr list --base dev --head "${branch}" --json number --jq 'length')
  [ "${count}" != "0" ]
}

set_framework_versions() {
  local schema_version addon_version
  schema_version="$1"
  addon_version="$2"
  NEW_SCHEMA_VERSION="${schema_version}" NEW_ADDON_VERSION="${addon_version}" perl -0pi -e '
    my $schema_version = $ENV{"NEW_SCHEMA_VERSION"};
    my $addon_version = $ENV{"NEW_ADDON_VERSION"};
    s@(<version>)[^<]+(</version>)@$1$addon_version$2@ or die "Failed to update framework version\n";
    s@(<schema\b[^>]*>\s*<version>)[^<]+(</version>)@$1$schema_version$2@s or die "Failed to update schema version\n";
  ' framework.xml
}
