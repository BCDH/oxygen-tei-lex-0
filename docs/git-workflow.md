# Git Workflow

This repository uses `dev` as the working integration branch and `main` as the release branch.

## Branch roles

- `dev` is the default branch for day-to-day work.
- feature and fix branches should be created from `dev`.
- `main` should not be used as a working branch.
- `main` is updated only by fast-forwarding it to `dev`.

## Daily work

Typical flow:

1. update `dev`
2. create a branch from `dev`
3. do the work on that branch
4. integrate the branch back into `dev`
5. test on `dev`
6. fast-forward `main` to `dev` when ready to publish

PRs are not mandatory in this repository. For simple maintainer changes, it is acceptable to merge branch work directly into `dev`. For larger, riskier, or automation-generated changes, a PR to `dev` is preferred because it provides clearer review and traceability.

## Integration rules

- keep history linear whenever possible
- prefer rebasing a work branch onto `dev` before integration if `dev` has moved
- avoid merge commits on `dev` and `main`
- treat CI on `dev` as the main verification step before promotion
- treat `main` as a mirror of a known-good `dev`

## Promote `dev` to `main`

When `dev` is ready for release, update `main` by fast-forward only:

```sh
git checkout main
git fetch origin
git merge --ff-only origin/dev
git push origin main
```

If the fast-forward fails, stop and resolve the divergence on branches before touching `main`.

## Releases

- release tags must be created from `main`, not from `dev`
- GitHub Pages and release publication follow the version currently on `main`
- if a change should not be publishable yet, it should stay off `main`

## Automation fit

Automation should follow the same branch policy:

- generated upgrade branches should branch from `dev`
- release-intake automation should target `dev`
- automation may open a PR to `dev`, but it must not assume PRs are mandatory
- promotion from `dev` to `main` remains a separate explicit step
