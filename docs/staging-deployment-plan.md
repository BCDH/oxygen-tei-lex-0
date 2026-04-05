# Staging Deployment Plan for `oxy.lex-0.org`

## Summary

Add a permanent staging environment for the `dev` branch at `dev.oxy.lex-0.org`, while keeping `main` as production at `oxy.lex-0.org`.

The deployment architecture should use Cloudflare as the public fronting layer, with production served by GitHub Pages from this repository and staging served from a generated staging branch in this same repository. Staging is always available, clearly marked as non-production, and explicitly blocked from indexing.

Target mapping:

- `main` -> production origin -> `oxy.lex-0.org`
- `dev` -> staging origin -> `dev.oxy.lex-0.org`

## Implementation Changes

### 1. Hosting architecture

Use two deployment outputs from this repository:

- production output for `main`
- staging output for `dev`, published to a generated branch such as `staging-pages`

Cloudflare responsibilities:

- terminate TLS for both `oxy.lex-0.org` and `dev.oxy.lex-0.org`
- route each hostname to its corresponding origin
- keep caches separated by hostname
- add response headers for staging crawler control if possible

Important constraint:

- production remains the standard GitHub Pages deployment for this repo
- staging is not a second repo; it is published from a generated branch in this same repo and exposed through Cloudflare routing

### 2. Branch-to-environment deployment flow

Production:

- trigger on pushes to `main`
- build package and stage site as today
- publish to the production static origin
- production remains the canonical public install endpoint

Staging:

- trigger on pushes to `dev`
- build package and stage site with the same packaging logic
- publish to the staging branch in this repository
- staging gets its own `addon.xml`, stable ZIP, and versioned ZIP under `dev.oxy.lex-0.org`

Required behavior:

- staging must mirror the real install flow, not just the landing page
- testers should be able to install directly from `https://dev.oxy.lex-0.org/addon.xml`
- production docs and UI must continue to point to `https://oxy.lex-0.org/addon.xml` as canonical

### 3. Staging-only behavior

Make staging visibly and operationally distinct from production.

Staging controls:

- inject a visible environment banner on all staging pages
- label staging as non-production in page copy where relevant
- add `<meta name="robots" content="noindex, nofollow, noarchive">`
- serve `robots.txt` with `Disallow: /`
- add `X-Robots-Tag: noindex, nofollow, noarchive` at Cloudflare if available
- avoid canonical tags pointing staging URLs at themselves
- do not link to staging from public production pages unless needed for maintainers

Add-on safety:

- staging `addon.xml` must reference staging-hosted ZIP URLs only
- production `addon.xml` must reference production-hosted ZIP URLs only
- do not share a stable ZIP URL across hosts

Operational posture:

- staging is persistent, not temporary
- staging may be unstable or ahead of production
- only production is supported for general users

### 4. Repo and workflow changes

Workflow layer:

- replace the current single-target Pages deployment model with explicit environment publishing for both `main` and `dev`
- keep packaging/build logic shared between both environments
- add an environment mode to site staging so the output can differ between prod and dev without hand-editing `web/`

Recommended script behavior:

- `prod` mode
  - production host values
  - normal indexability
  - no staging banner
- `dev` mode
  - staging host values
  - noindex controls
  - staging banner
  - staging-specific descriptor/install URLs

Repo docs to update:

- `Readme.md` with both deployment endpoints and a note that only production is canonical
- `docs/git-workflow.md` to state that `dev` deploys to persistent staging
- release-intake automation plan so automation targeting `dev` assumes a live staging environment for validation

### 5. Cloudflare and DNS configuration

Create these DNS/public routes:

- `oxy.lex-0.org` -> production origin
- `dev.oxy.lex-0.org` -> staging route in front of this repository's generated staging branch

Cloudflare configuration:

- enable TLS for both hosts
- disable or carefully scope aggressive caching for `addon.xml`
- set short cache TTL or bypass caching for:
  - `/addon.xml`
  - stable ZIP URL if you want immediate update visibility
- optional but recommended:
  - response header transform for `X-Robots-Tag` on `dev.oxy.lex-0.org`
  - cache rules separating HTML from ZIP artifacts

If using GitHub Pages as the underlying production origin:

- keep `oxy.lex-0.org` mapped through the standard GitHub Pages deployment for this repository
- route `dev.oxy.lex-0.org` through Cloudflare to content generated from the staging branch in this same repository

## Public Interfaces / Environment Contracts

Public production endpoints:

- `https://oxy.lex-0.org/`
- `https://oxy.lex-0.org/addon.xml`
- `https://oxy.lex-0.org/oxygen-tei-lex-0.zip`

Public staging endpoints:

- `https://dev.oxy.lex-0.org/`
- `https://dev.oxy.lex-0.org/addon.xml`
- `https://dev.oxy.lex-0.org/oxygen-tei-lex-0.zip`

Branch contract:

- `main` publishes production only
- `dev` publishes staging only

Search-engine contract for staging:

- `noindex`, `nofollow`, `noarchive`
- `robots.txt` disallow all
- visible staging banner
- no public canonical promotion

## Test Plan

### Host routing

- verify `oxy.lex-0.org` serves production origin only
- verify `dev.oxy.lex-0.org` serves staging origin only
- verify the two hosts return different environment markers when `dev` and `main` differ

### Install flow

- verify production `addon.xml` installs production ZIP
- verify staging `addon.xml` installs staging ZIP
- verify ZIP downloads resolve correctly on both hosts

### Crawler controls

- verify staging HTML contains `meta robots` noindex
- verify `dev.oxy.lex-0.org/robots.txt` disallows all
- verify `X-Robots-Tag` is present on staging responses if configured in Cloudflare
- verify production does not inherit staging crawler restrictions

### Cache correctness

- verify `addon.xml` updates promptly after deploy
- verify staging and production artifacts do not bleed across caches
- verify stable ZIP URLs on each host resolve to the correct environment's current artifact

### Workflow validation

- push a test change to `dev` and confirm only staging updates
- fast-forward `main` to `dev` and confirm production updates afterward
- confirm release tags remain production-only behavior tied to `main`

## Assumptions And Defaults

- Staging should be permanent, not temporary.
- Public staging hostname is `dev.oxy.lex-0.org`.
- Cloudflare is the fronting layer.
- Production and staging are served from this repository.
- Production uses the normal GitHub Pages deployment path, while staging is published to a generated branch and exposed separately through Cloudflare.
- Staging is public-but-noindex, not access-restricted.
- Production remains the only canonical user-facing install endpoint.
