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
  - required: RNG
  - optional but preferred: RNC and XSD
  - `published_at`

Upstream validation before dispatch:

- release/tag is annotated and published successfully
- required release assets exist
- dispatch is sent only once per successful release run

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

- upstream schema version fits the current line that can reuse the existing `0.9.4+` template/description band
- required upstream asset names or mappings are recognized
- the downstream build metadata generation completes cleanly

Automation must fail without creating integration work when:

- schema version implies a new compatibility band, such as a structural jump requiring new templates/descriptions
- upstream release assets are missing or renamed unexpectedly
- the downstream repo already contains partial/manual work for that schema version
- `ant` build fails

Failure output should be explicit and actionable, with the reason surfaced in the workflow summary.

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

Keep all repo-tracked edits in source files only; do not edit packaged zip artifacts directly.

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

### Versioning policy

When upstream publishes a new Lex-0 release:

- downstream framework version bumps minor
- downstream patch resets to `0`

Example:

- current `2.0.0` + upstream `0.9.6` release
- next downstream version becomes `2.1.0`

## Test Plan

### Happy path

- simulate a dispatch for a new `0.9.x` release with valid published assets
- verify schema files land in `src/schemas/<version>/`
- verify `framework.xml` schema version updates correctly
- verify framework version minor bump/reset is correct
- verify `ant` succeeds
- verify an integration branch from `dev` is created with the expected commit content
- if PR mode is enabled, verify a PR to `dev` is created with the expected title/body

### Idempotence

- resend the same dispatch
- confirm no second integration branch or PR is created

### Validation failures

- missing RNG asset
- malformed tag/version payload
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
