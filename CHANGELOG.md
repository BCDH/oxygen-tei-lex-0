# Changelog

This file records maintainer-facing release notes for the TEI Lex-0 oXygen
Framework.

Guidelines:

- Keep entries short and concrete.
- Record user-visible fixes, support changes, and important internal changes.
- Use `web/addon.xml` for shorter end-user release notes shown inside oXygen.
- Move items from `Unreleased` into a versioned section when a release is cut.

## Unreleased

## 2.0.1 - 2026-04-23

### Fixed

- Corrected the TEI Lex-0 `0.9.4` validation schema reference from `TEILex0.rng` to `lex-0.rng` in the bundled framework configuration as per [#6](https://github.com/BCDH/oxygen-tei-lex-0/issues/6).

### Changed

- Removed legacy TEI Lex-0 `0.9.0` dictionary templates as per [#5](https://github.com/BCDH/oxygen-tei-lex-0/issues/5).
- Documented the Cloudflare Worker setup for the staging site.

## 2.0.0

### Changed

- Replaced the legacy `teilex0-oxygen-framework` add-on with the
  `oxygen-tei-lex-0` package and identifier.
- Added support for TEI Lex-0 `0.9.4` and `0.9.5`.
