# Contributing to the Workspace

The workspace tracks shared documentation and the exact revisions of the OBS
plugin and web application. It is not a monorepo: `hd-obs` and `hd-web` are
independent Git submodules.

## Choose the right repository

- Change shared project documentation, workspace guidance, or submodule
  pointers here.
- Change the macOS OBS plugin in `hd-obs/`.
- Change the web application, Prisma schema, or web CI in `hd-web/`.

Read the closest `AGENTS.md` before changing files. Child-repository guidance
overrides this workspace guide.

## Branch and pull-request flow

Create a typed working branch from `origin/develop` and open ordinary pull
requests to `develop`. Promote the integrated branch to `main` in a separate
pull request. Do not push directly to either protected branch.

Use Conventional Commit subjects, keep pull requests focused, and describe the
validation performed. For selected same-repository GitHub Issues, use an
issue-number branch and include `Closes #<issue>` in the PR body. Do not
automatically change GitHub Issue assignment, labels, or state.

## Submodule updates

When updating a pointer, ensure the child revision is already pushed to its
own remote:

```sh
cd hd-web
git switch develop
git pull --ff-only

cd ..
git add hd-web
git commit -m "chore: update hd-web submodule"
```

Use the corresponding `hd-obs` commands for plugin updates. Do not stage a
submodule pointer that references an unpushed child commit.

## Commit signatures and sensitive data

Commits and tags are signed by default and GitHub enforces signed commits.
Never bypass that protection. Do not commit credentials, access tokens,
private user data, generated build output, or raw keystroke content.

## Validation

Documentation-only workspace changes should at least pass `git diff --check`.
Run the relevant child project's documented checks whenever a submodule pointer
changes so the workspace records a known-good revision.
