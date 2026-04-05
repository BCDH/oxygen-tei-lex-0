#!/usr/bin/env bash

set -euo pipefail

root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
framework_file="${root_dir}/framework.xml"

mode="prod"
if [ "${1:-}" = "prod" ] || [ "${1:-}" = "dev" ]; then
  mode="$1"
  shift
fi

stage_dir="${1:-${root_dir}/site}"

project_id=$(awk -F'[<>]' '$2 == "id" { print $3; exit }' "${framework_file}")
project_version=$(awk -F'[<>]' '$2 == "version" { print $3; exit }' "${framework_file}")
schema_version=$(awk -F'[<>]' '$2 ~ /^schema([[:space:]]|$)/ { in_schema = 1 } in_schema && $2 == "version" { print $3; exit }' "${framework_file}")

artifact_dir="${root_dir}/build/${schema_version}"
stable_zip="${artifact_dir}/${project_id}.zip"
versioned_zip="${artifact_dir}/${project_id}-${project_version}.zip"

case "${mode}" in
  prod)
    public_host="https://oxy.lex-0.org"
    public_domain="oxy.lex-0.org"
    ;;
  dev)
    public_host="https://oxy-dev.lex-0.org"
    public_domain="oxy-dev.lex-0.org"
    ;;
  *)
    echo "Unsupported site mode: ${mode}" >&2
    exit 1
    ;;
esac

"${root_dir}/scripts/build-package.sh"

rm -rf "${stage_dir}"
mkdir -p "${stage_dir}"

rsync -a --exclude='*.zip' "${root_dir}/web/" "${stage_dir}/"
cp "${stable_zip}" "${stage_dir}/"
cp "${versioned_zip}" "${stage_dir}/"

printf '%s\n' "${public_domain}" > "${stage_dir}/CNAME"
: > "${stage_dir}/.nojekyll"

if [ "${mode}" = "dev" ]; then
  cat > "${stage_dir}/robots.txt" <<'EOF'
User-agent: *
Disallow: /
EOF
else
  rm -f "${stage_dir}/robots.txt"
fi

PUBLIC_HOST="${public_host}" MODE="${mode}" perl -0pi -e '
  my $host = $ENV{"PUBLIC_HOST"};
  my $mode = $ENV{"MODE"};
  my $robots = $mode eq "dev"
    ? qq{    <meta name="robots" content="noindex, nofollow, noarchive" />\n}
    : q{};
  my $env_meta = qq{    <meta name="deployment-environment" content="$mode" />\n};
  my $body_attr = qq{<body data-environment="$mode">};
  my $banner = q{};

  if ($mode eq "dev") {
    $banner = <<'"'"'EOF_BANNER'"'"';
    <div class="env-banner" data-environment-banner="dev">
      <strong>Staging environment.</strong> This site is published from the
      <code>dev</code> branch for testing before production release.
    </div>
EOF_BANNER
  }

  s@(<meta\s+name="description"[^>]+/>\n)@$1$env_meta$robots@;
  s@</style>@\n      .env-banner {\n        padding: 0.85rem 1rem;\n        border-bottom: 1px solid #d95f49;\n        background: #ed6f59;\n        color: #ffffff;\n        font-size: 0.95rem;\n        line-height: 1.5;\n        text-align: center;\n      }\n\n      .env-banner code {\n        background: rgba(255, 255, 255, 0.16);\n        border: 1px solid rgba(255, 255, 255, 0.24);\n        border-radius: 4px;\n        padding: 0.1rem 0.35rem;\n      }\n    </style>@;
  s@<body>@$body_attr@;
  s@<body\b[^>]*>@${body_attr}\n${banner}@ if $mode eq "dev";
  s@https://oxy\.lex-0\.org/addon\.xml@$host/addon.xml@g;
  s@window\.location\.origin \|\| "https://oxy\.lex-0\.org"@window.location.origin || "$host"@g;
' "${stage_dir}/index.html"

if [ "${mode}" = "dev" ]; then
  perl -0pi -e '
    s#(<body>\s*)#$1<p><strong>Staging build:</strong> this descriptor is intended for testing from the <code>dev</code> branch and should not be used as the public installation endpoint.</p>\n                         #;
  ' "${stage_dir}/addon.xml"
fi

printf 'Staged %s site in %s\n' "${mode}" "${stage_dir}"
