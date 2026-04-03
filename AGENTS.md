# AGENTS.md

## Purpose

This repository contains an oXygen XML Editor framework for TEI Lex-0. The distributable package is built from `src/` and published from `web/`.

## Repository Layout

- `src/`: source of the framework package copied into the zip during build
- `src/teilex0.exf`: main framework definition
- `src/catalog.xml`: catalog mappings for local resources
- `src/_descriptions/`: template descriptions shown in oXygen
- `src/css/`: Author mode styles
- `src/resources/`: transformation and validation scenario definitions
- `src/schemas/`: bundled schema versions
- `src/schematron-quick-fixes/`: Schematron QuickFix rules
- `src/templates/`: starter TEI Lex-0 documents
- `src/xproc/`, `src/xquery/`, `src/xslt/`: transformation logic
- `assets/`: XSLT and catalog assets used by Ant to generate/update framework metadata
- `web/`: GitHub Pages site, add-on metadata, and published zip artifacts
- `build.xml`: Ant packaging script
- `framework.xml`: source of framework id, package version, and schema version used by the build
- `oxygen-tei-lex-0.xpr`: oXygen project file for local development
- `test/`: minimal local utilities only; there is no automated test suite here

## Working Rules

- Treat this as a framework/configuration repo, not a conventional application.
- Keep edits narrowly scoped to the affected framework resource.
- Prefer editing source files in `src/`; do not hand-edit packaged zip files in `web/`.
- In `src/css/`, edit `.less` sources rather than generated `.css` files unless the task is explicitly about generated output.
- Preserve XML formatting and namespace declarations carefully. Small syntax mistakes can break framework loading in oXygen.
- When changing behavior tied to a specific TEI Lex-0 version, check whether the same change is needed in more than one schema/catalog subtree under `src/schemas/`.
- Treat files under `build/` as generated output. Regenerate them instead of editing them manually.

## Build And Verification

- Build the distributable package with `ant` from the repository root.
- The Ant `zip` target reads versioning values from `framework.xml`.
- The Ant build creates `build/<schema.version>/oxygen-tei-lex-0.zip`, copies a versioned zip to the same schema-specific build directory, and updates both `web/oxygen-tei-lex-0.zip` and `web/oxygen-tei-lex-0-<version>.zip`.
- `build/` is ignored by git. Verify generated files there freely.
- There is no real automated test suite. Validation is mainly:
  - run `ant`
  - inspect changed XML/Less/XSLT/XQuery files for syntax errors
  - if relevant, open the framework in oXygen using `oxygen-tei-lex-0.xpr`

## Release Consistency

When preparing a release or changing the published package version, keep these in sync:

- `framework.xml`: framework id, add-on version, schema version, and schema URL parameters
- `build.xml`: build logic that consumes values from `framework.xml`
- `web/addon.xml`: source metadata transformed for publishing
- `web/`: committed versioned zip artifact if the release package changed

If the schema version changes, also check generated or copied resources under `src/schemas/<version>/` and any template or description folders that are version-specific.

## Common Edit Targets

- Framework registration or UI behavior: `src/teilex0.exf`, `src/teilex0.framework`, `src/i18n/translation.xml`
- Validation behavior: `src/resources/validation.scenarios`, `src/schematron-quick-fixes/`, `src/schemas/`
- Transformations: `src/resources/transformation.scenarios` plus corresponding files in `src/xproc/`, `src/xquery/`, or `src/xslt/`
- Author view styling: `src/css/*.less`
- New document templates: `src/templates/`
- Build-time metadata transforms: `assets/xslt/`, `framework.xml`, `web/addon.xml`

## Avoid

- Do not restructure `src/` casually; `build.xml` packages it as-is.
- Do not update `web/` zip names, add-on ids, or version text without also checking `framework.xml` and `build.xml`.
- Do not assume CI validates framework integrity. Most correctness checks are manual.
