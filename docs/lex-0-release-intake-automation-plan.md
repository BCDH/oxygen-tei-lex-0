# Cross-Repo Lex-0 Release Intake Automation

## Summary

Build a two-repo automation where `BCDH/tei-lex-0` emits an explicit `repository_dispatch` event after a release is fully published, and `BCDH/oxygen-tei-lex-0` consumes that event to prepare an upgrade branch from `dev`.

The downstream automation will:

- trust only immutable upstream release assets
- import the new schema bundle into `src/schemas/<schema-version>/`
- bump this framework's version by minor and reset patch to `0`
- regenerate framework metadata needed for the new schema version
- run `ant` verification
- prepare an integration branch for `dev`

If the upstream release falls outside the current compatibility model, automation stops without creating an integration branch.

This automation is intentionally narrow. It should support only the current post-`0.9.4` schema layout already used by this repository. Older schema layouts and future structural changes remain manual.

## Runtime Flow

The runtime sequence of the finished system is:

1. `BCDH/tei-lex-0` publishes a release and its schema assets.
2. `BCDH/tei-lex-0` emits `repository_dispatch` with the agreed payload.
3. `BCDH/oxygen-tei-lex-0` validates the payload and release assets.
4. `BCDH/oxygen-tei-lex-0` prepares and pushes an integration branch from `dev`.
5. maintainers review or merge that branch into `dev` according to the repository workflow.
6. promotion from `dev` to `main` remains a separate manual fast-forward step.

## Implementation Sequence

The recommended implementation order is different from the runtime flow:

1. implement the downstream receiver in `BCDH/oxygen-tei-lex-0` first
2. make the downstream workflow testable with a simulated `repository_dispatch` payload
3. implement the upstream sender in `BCDH/tei-lex-0` second
4. run an end-to-end test from upstream to downstream
5. enable the upstream dispatch step in the real release workflow

This order reduces risk because the downstream side contains most of the validation, file-mapping, and branch-preparation logic. Once the receiver contract is stable, the upstream sender is comparatively small.

## Implementation Changes

### 1. Upstream release announcement in `BCDH/tei-lex-0`

Add a final release-notify step to the upstream tag/release workflow, after release assets are successfully published.

Dispatch contract:

- Event type: `tei_lex_0_released`
- Target repo: `BCDH/oxygen-tei-lex-0`
- Authentication: dedicated PAT or GitHub App token stored in upstream secrets, scoped only to dispatch to the downstream repo
- Payload fields:
  - `source_repo`: `BCDH/tei-lex-0`
  - `tag`: upstream release tag, e.g. `v0.9.6`
  - `schema_version`: normalized schema version, e.g. `0.9.6`
  - `release_url`
  - `commit_sha`
  - `assets`: URLs for the published schema files the downstream repo needs
  - required: `rng_url`
  - optional but preferred: `rnc_url` and `xsd_url`
  - `published_at`

Upstream validation before dispatch:

- release/tag is annotated and published successfully
- required release assets exist
- dispatch is sent only once per successful release run

Required upstream release asset contract:

- asset basenames must be `lex-0.rng`, optional `lex-0.rnc`, and optional `lex-0.xsd`
- the downstream automation should treat any other required-name pattern as unsupported and fail early
- `catalog.xml` is not expected from upstream and remains locally generated/copied by downstream automation

### 2. Downstream intake workflow in `BCDH/oxygen-tei-lex-0`

Add a new workflow triggered by `repository_dispatch` for `tei_lex_0_released`.

Workflow behavior:

- verify `client_payload.source_repo == BCDH/tei-lex-0`
- validate tag/version format
- reject duplicate work if:
  - `src/schemas/<schema_version>/` already exists, or
  - an open PR or existing automation branch already targets that schema version, or
  - the repo version already references that schema version
- download the published upstream release assets into a temp workspace
- verify required files are present and non-empty
- normalize filenames to this repo's expected structure under `src/schemas/<schema-version>/`
- update `framework.xml`
  - set `<schema><version>` to the new upstream schema version
  - bump framework version from `MAJOR.MINOR.PATCH` to `MAJOR.(MINOR+1).0`
- refresh framework metadata using the existing Ant/XSLT path rather than hand-editing generated references
- regenerate `web/addon.xml` content for the new framework/schema version
- build with `ant`
- create a branch like `automation/lex0-v0.9.6`
- commit the change set
- push the branch for integration into `dev`
- optionally open a PR to `dev`, but do not require PR-only workflow assumptions

Exact downstream file mapping for supported versions:

- create `src/schemas/<schema_version>/`
- write upstream `lex-0.rng` to `src/schemas/<schema_version>/lex-0.rng`
- if present, write upstream `lex-0.rnc` to `src/schemas/<schema_version>/lex-0.rnc`
- if present, write upstream `lex-0.xsd` to `src/schemas/<schema_version>/lex-0.xsd`
- create `src/schemas/<schema_version>/catalog.xml` from the current `0.9.5` catalog template, changing only the schema-version path references needed for the new directory
- do not attempt to backfill legacy filenames such as `TEILex0.rng`

Exact duplicate-detection rule:

- the authoritative automation branch name is `automation/lex0-v<schema_version>`
- if that remote branch already exists, the workflow must stop
- if a PR exists whose head branch is `automation/lex0-v<schema_version>`, the workflow must stop
- if `framework.xml` already has `<schema><version>` equal to `<schema_version>`, the workflow must stop

If a PR is created, its content should be:

- title: `chore: integrate TEI Lex-0 v0.9.6`
- body includes:
  - upstream tag and release URL
  - imported asset list
  - old/new framework version
  - old/new schema version
  - automation run URL

Downstream branch handling:

- base branch: `dev`
- automation branch naming: `automation/lex0-v0.9.6`
- duplicate detection must consider both open PRs and already-pushed automation branches for the same schema version
- promotion from `dev` to `main` remains a separate manual fast-forward step following the repository workflow in `docs/git-workflow.md`

### 3. Compatibility guardrails

Treat the current framework as compatible only with the existing known template/description regime.

Automation may proceed only when all of these hold:

- upstream schema version is greater than or equal to `0.9.5`
- upstream release assets use the current `lex-0.*` naming pattern already present in `src/schemas/0.9.5/`
- the existing `0.9.5` catalog template can be reused by changing version-directory references only
- required upstream asset names or mappings are recognized
- the downstream build metadata generation completes cleanly

Automation must fail without creating integration work when:

- schema version implies a new compatibility band, such as a structural jump requiring new templates/descriptions
- upstream release assets are missing or renamed unexpectedly
- the downstream repo already contains partial/manual work for that schema version
- `ant` build fails

Failure output should be explicit and actionable, with the reason surfaced in the workflow summary.

Explicit non-goals for the first implementation:

- no automation for `0.9.0` to `0.9.4` style schema layouts
- no automation for releases that require new templates, descriptions, or framework-association rules
- no automation for rewriting historical support entries beyond appending the new supported release

### 4. Supporting scripts and repo conventions

Add a small downstream script layer so the workflow logic stays deterministic and testable.

Recommended script responsibilities:

- parse and validate dispatch payload
- compute next framework version
- fetch and verify release assets
- stage schema files into repo layout
- run the existing metadata regeneration/build commands
- detect compatibility breaks and duplicates
- emit a PR summary payload
- emit branch metadata and, if used, PR summary payload

Recommended script split:

- `scripts/intake-lex0-release.sh`: main orchestration entrypoint for a validated dispatch payload
- `scripts/lib/lex0-release.sh`: shared functions for version parsing, duplicate detection, and asset validation
- `scripts/lib/lex0-addon.sh`: controlled updates to `web/addon.xml`

Keep all repo-tracked edits in source files only; do not edit packaged zip artifacts directly.

Allowed automated edits:

- `framework.xml`
- `src/schemas/<schema_version>/lex-0.rng`
- `src/schemas/<schema_version>/lex-0.rnc`
- `src/schemas/<schema_version>/lex-0.xsd`
- `src/schemas/<schema_version>/catalog.xml`
- `web/addon.xml`

Disallowed automated edits in the first implementation:

- templates under `src/templates/`
- description content under `src/_descriptions/`
- historical schema directories
- deprecated legacy add-on entry in `web/addon.xml`

## Public Interfaces / Contracts

### Upstream-to-downstream event contract

`repository_dispatch` payload must be treated as the formal integration API between the repos.

Minimum required fields:

- `event_type = tei_lex_0_released`
- `source_repo`
- `tag`
- `schema_version`
- `release_url`
- `commit_sha`
- `assets.rng_url`

Preferred fields:

- `assets.rnc_url`
- `assets.xsd_url`
- `published_at`

Payload validation rules:

- `tag` must equal `v<schema_version>`
- `schema_version` must match `^[0-9]+\\.[0-9]+\\.[0-9]+$`
- `assets.rng_url` basename must be `lex-0.rng`
- if present, `assets.rnc_url` basename must be `lex-0.rnc`
- if present, `assets.xsd_url` basename must be `lex-0.xsd`

### Versioning policy

When upstream publishes a new Lex-0 release:

- downstream framework version bumps minor
- downstream patch resets to `0`

Example:

- current `2.0.0` + upstream `0.9.6` release
- next downstream version becomes `2.1.0`

### `web/addon.xml` update policy

Automation may update only these parts of `web/addon.xml`:

- `<xt:version>` for the `oxygen-tei-lex-0` extension
- the visible add-on version text inside the main extension description
- the supported-version list under the main extension description by prepending the new schema version entry
- the history block for the current framework version by inserting a short generated note that support for the new schema version was added

Automation must not modify:

- the deprecated `teilex0-oxygen-framework` extension block
- license text
- unrelated historical entries for older framework releases

## Test Plan

### Happy path

- simulate a dispatch for a new `0.9.x` release with valid published assets
- verify schema files land in `src/schemas/<version>/`
- verify the new schema directory contains the expected `lex-0.*` filenames and generated `catalog.xml`
- verify `framework.xml` schema version updates correctly
- verify framework version minor bump/reset is correct
- verify `web/addon.xml` only changes in the allowed sections
- verify `ant` succeeds
- verify an integration branch from `dev` is created with the expected commit content
- if PR mode is enabled, verify a PR to `dev` is created with the expected title/body

### Idempotence

- resend the same dispatch
- confirm no second integration branch or PR is created

### Validation failures

- missing RNG asset
- malformed tag/version payload
- wrong asset basename such as `TEILex0.rng`
- mismatched sender repo
- pre-existing schema directory
- pre-existing open PR or pushed automation branch for the same schema version

### Compatibility stop

- simulate a release outside the supported compatibility band
- confirm the workflow fails early and creates no integration branch

### Downstream build integrity

- run existing CI and Pages/release workflows unchanged on the automation branch after automation-generated changes
- confirm packaged zip output still comes from the normal build path

## Assumptions And Defaults

- Trigger mechanism is `repository_dispatch`.
- Downstream automation works from `dev`, not `main`.
- Opening a PR to `dev` is optional and should be configurable; the repository workflow does not require PRs for every change.
- The automation does not auto-merge, fast-forward `main`, or auto-tag this repo.
- Upstream published release assets are the source of truth; no downstream rebuild of upstream is done.
- Compatibility breaks require manual follow-up and block automated integration branch creation.
- The existing downstream Ant/XSLT metadata path remains authoritative for updating framework references.
- Required secrets/tokens can be added in both repositories with least-privilege scopes.
- The first implementation targets only releases that look like the current `0.9.5` schema layout and metadata expectations.
