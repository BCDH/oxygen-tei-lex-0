#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
framework_file="${root_dir}/framework.xml"
stage_dir="${1:-${root_dir}/site}"

project_id=$(awk -F'[<>]' '$2 == "id" { print $3; exit }' "${framework_file}")
project_version=$(awk -F'[<>]' '$2 == "version" { print $3; exit }' "${framework_file}")
schema_version=$(awk -F'[<>]' '$2 ~ /^schema([[:space:]]|$)/ { in_schema = 1 } in_schema && $2 == "version" { print $3; exit }' "${framework_file}")

artifact_dir="${root_dir}/build/${schema_version}"
stable_zip="${artifact_dir}/${project_id}.zip"
versioned_zip="${artifact_dir}/${project_id}-${project_version}.zip"

"${root_dir}/scripts/build-package.sh"

rm -rf "${stage_dir}"
mkdir -p "${stage_dir}"

rsync -a --exclude='*.zip' "${root_dir}/web/" "${stage_dir}/"
cp "${stable_zip}" "${stage_dir}/"
cp "${versioned_zip}" "${stage_dir}/"
