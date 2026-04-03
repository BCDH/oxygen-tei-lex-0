#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
framework_file="${root_dir}/framework.xml"

project_id=$(awk -F'[<>]' '$2 == "id" { print $3; exit }' "${framework_file}")
project_version=$(awk -F'[<>]' '$2 == "version" { print $3; exit }' "${framework_file}")
schema_version=$(awk -F'[<>]' '$2 ~ /^schema([[:space:]]|$)/ { in_schema = 1 } in_schema && $2 == "version" { print $3; exit }' "${framework_file}")

artifact_dir="${root_dir}/build/${schema_version}"
stable_zip="${artifact_dir}/${project_id}.zip"
versioned_zip="${artifact_dir}/${project_id}-${project_version}.zip"

ant -f "${root_dir}/build.xml" zip "$@"

test -f "${stable_zip}"
test -f "${versioned_zip}"

printf 'Built %s and %s\n' "${stable_zip}" "${versioned_zip}"
