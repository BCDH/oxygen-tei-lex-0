# TEI Lex-0 oXygen Framework

Add-on for [oXygen XML Editor](https://www.oxygenxml.com/xml_editor.html) with tools for editing, transforming, and analyzing dictionaries in [TEI Lex-0](https://lex-0.org) format.

The framework is associated only with files from `http://www.tei-c.org/ns/1.0` namespace with `TEI` root element and `@type` attribute with value `lex-0'`.

## Supported version of TEI Lex-0

- [0.9.5](https://github.com/BCDH/tei-lex-0/tree/gh-pages/releases/v0.9.5)
- [0.9.4](https://github.com/BCDH/tei-lex-0/tree/gh-pages/releases/v0.9.4)
- [0.9.3](https://github.com/DARIAH-ERIC/lexicalresources/releases/tag/v0.9.3)
- [0.9.2](https://github.com/DARIAH-ERIC/lexicalresources/releases/tag/v0.9.2)
- [0.9.1](https://github.com/DARIAH-ERIC/lexicalresources/releases/tag/v0.9.1)
- [0.9.0](https://github.com/DARIAH-ERIC/lexicalresources/releases/tag/v0.9.0)

## Features

- templates
  - dictionary with `<teiHeader>` and `<text>`
  - inserting entry with basic structure
- author view
  - separate view of the body with entries
  - separate view of the teiHeader
  - colored parts of the text (grammar, defintion etc.)
- trnasformation scenarios
  - extraction of the list of the headwords
  - statistics of used elements and attributes
  - export to PDF
  - merging included entries (using XInclude) in one file
- Schematron QuickFixes
  - `<bibl>` element is not allowed in `<sense>`
  - `<def>` element is not allowed in `<cit>`

## Build

TEI Lex-0 oXygen Framework can be built locally using ANT:

- run `ant` in the repository root
- generated archives are written to `build/<schema-version>/`

GitHub Actions publishes the current installable package to GitHub Pages:

- stable package: `https://oxy.lex-0.org/oxygen-tei-lex-0.zip`
- versioned package: `https://oxy.lex-0.org/oxygen-tei-lex-0-<version>.zip`
- staging package: `https://oxy-dev.lex-0.org/oxygen-tei-lex-0.zip`

Historical package archives are published as GitHub Release assets in this repository.

Cross-repo release intake is also automated:

- `BCDH/tei-lex-0` publishes `schemas.zip` and `schemas.tar.gz` as release assets
- a release notification dispatch from `BCDH/tei-lex-0` triggers intake in this repository
- this repository creates `automation/lex0-v<schema-version>` from `dev`
- the intake workflow always opens a PR to `dev`

### Site layout

- `web/` contains the tracked source files for the website and add-on descriptor
- `site/` is a generated staging directory used for GitHub Pages deployment
- `scripts/prepare-pages.sh` prepares the Pages site for either production or staging and adds the current ZIP artifacts from `build/<schema-version>/`
- edit files in `web/`, not in `site/`

## Installation

The canonical installation endpoint is `https://oxy.lex-0.org/addon.xml`.

A persistent staging install endpoint is available at `https://oxy-dev.lex-0.org/addon.xml`. It is intended for testing the `dev` branch before production promotion and should not be treated as the public installation URL.

The current framework package and the deprecated legacy package are both referenced from that descriptor. Historical downloads are available from the repository releases page.

The installation process of the framework is described in the [documentation](https://www.oxygenxml.com/doc/versions/25.1/ug-editor/topics/installing-and-updating-add-ons.html) of the oXygen XML editor.

## Development

Download and unzip source code, or clone the Git Hub repository on your computer.

Open `teilex0-oxygen-framework.xpr` project file from the root directory of this repository in the oXygen XML Editor.

Following steps should be done only once. or if you change the location of your repository on the local disc.

In oXygen XML Editor from the `Options` menu choose `Preferences...`, then `Document Type Association` > `Locations` (1), click on `Add` button (2), select the path to the local repository (3), click on `OK` (4) in the `Choose framework directory` dialog and again `OK` (5) in main `Preferences` window.

![Setting Document Type Association Locations](docs/images/oXygen_Document-Type-Association-Locations.png)

After applying these steps there will be new item in the `Document Type Association` list called `TEI Lex-0`.

![Document Type Association TEI Lex-0](docs/images/oXygen_Document-Type-Association-TEI-Lex-0.png)

### Contribution

You can extend and change the behaviour of the oXygen XML Editor framework changing following files in the [src](./src) directory:

- `teilex0.exf`
  - main file with settings for framework components
- `catalog.xml`
  - catalog files with the association of the external resources with local files

You can also change files in the following subdirectories:

- `_descriptions`
  - directory with descriptions of available templates
- `css`
  - directory with Cascading Style Sheets files; edit only `.less` files, `.css` files are generating automatically after saving `.less` file.
- `i18n`
  - translation of the user interface
- `resources`
  - different types of components used in the framework, for example transformation scenarios
- `schemas`
  - RNG or other types of schema used in the validation scenarios of edited files
  - catalog files with the association of the external resources with local files
- `schematron-quick-fixes`
  - schematron rules with [quick fixes](https://www.schematron-quickfix.com) -`templates`
  - templates for newly inserted documents, contain basic structure of valid TEI Lex-0 document -`xproc`
  - XProc 1.0 steps used in XPRoc transformation scenarios -`xquery`
  - XQuery files used in XQuery transformation scenarios -`xslt`
  - XSLT files used in XSLT transformation scenarios

## Releases

- pushes to `dev` and `main` run CI packaging validation
- pushes to `main` rebuild and publish the production site at `oxy.lex-0.org`
- pushes to `dev` rebuild and publish the staging site at `oxy-dev.lex-0.org`
- pushes of `v*` tags publish the current versioned ZIP as a GitHub Release asset
- upstream `BCDH/tei-lex-0` releases can automatically open upgrade PRs here by importing `schemas.zip` or `schemas.tar.gz` into a new schema directory
- historical `teilex0-oxygen-framework` releases can be recreated from git history with `scripts/publish-historical-releases.sh`

Staging publication requires:

- generated branch `staging-pages` in this repository, or a repository variable `STAGING_PAGES_BRANCH` if you want a different branch name
- workflow permission to push to that generated branch with the default `GITHUB_TOKEN`

Release-intake automation requires:

- repository secret `OXYGEN_TEI_LEX0_INTAKE_TOKEN` in `BCDH/oxygen-tei-lex-0`
- repository secret `OXYGEN_TEI_LEX0_DISPATCH_TOKEN` in `BCDH/tei-lex-0`

## Workflow Docs

- git workflow: [docs/git-workflow.md](docs/git-workflow.md)
