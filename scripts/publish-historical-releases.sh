#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
repo_full_name="BCDH/oxygen-tei-lex-0"
tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

historical_releases=$(
  cat <<'EOF'
v1.2.0|dcd487e|dcd487e|web/teilex0-oxygen-framework-1.2.0.zip|Legacy 1.2.0 binary imported from the original daliboris/teilex0-oxygen-framework history. No standalone release commit exists in the canonical repository.
v1.3.0|dcd487e|dcd487e|web/teilex0-oxygen-framework-1.3.0.zip|Legacy 1.3.0 binary imported from the original daliboris/teilex0-oxygen-framework history. No standalone release commit exists in the canonical repository.
v1.4.0|dcd487e|dcd487e|web/teilex0-oxygen-framework-1.4.0.zip|Legacy 1.4.0 binary reconstructed from the earliest available framework commit.
v1.5.0|c1f54fb|c1f54fb|web/teilex0-oxygen-framework-1.5.0.zip|Release 1.5.0 with Schematron Quick Fixes.
v1.5.1|f800eb3|f800eb3|web/teilex0-oxygen-framework-1.5.1.zip|Release 1.5.1 with the default Quick Fix validation scenario.
v1.5.2|0e5de6f|0e5de6f|web/teilex0-oxygen-framework-1.5.2.zip|Release 1.5.2 with xml:lang propagation in inserted cit elements.
EOF
)

while IFS='|' read -r tag_name tag_commit asset_commit asset_path release_notes; do
  [ -n "${tag_name}" ] || continue

  asset_name=$(basename "${asset_path}")
  asset_file="${tmp_dir}/${asset_name}"

  git show "${asset_commit}:${asset_path}" > "${asset_file}"

  if ! git rev-parse -q --verify "refs/tags/${tag_name}" >/dev/null; then
    git tag -a "${tag_name}" "${tag_commit}" -m "${tag_name}"
  fi

  if ! git ls-remote --exit-code --tags origin "${tag_name}" >/dev/null 2>&1; then
    git push origin "refs/tags/${tag_name}"
  fi

  if gh release view "${tag_name}" --repo "${repo_full_name}" >/dev/null 2>&1; then
    gh release upload "${tag_name}" "${asset_file}" --repo "${repo_full_name}" --clobber
  else
    gh release create "${tag_name}" "${asset_file}" --repo "${repo_full_name}" --title "${tag_name}" --notes "${release_notes}"
  fi

  printf 'Published %s from %s\n' "${tag_name}" "${asset_path}"
done <<EOF
${historical_releases}
EOF
