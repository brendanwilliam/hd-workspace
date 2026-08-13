# Hands Diff Workspace

This repository is the coordination point for Hands Diff. It keeps shared
project documentation and workspace guidance together while the deliverable
code remains in two independent Git submodules:

| Project | Purpose | Primary technology |
| --- | --- | --- |
| [`hd-obs`](hd-obs/) | macOS OBS plugin that captures and summarizes input activity | C++, Objective-C++, CMake |
| [`hd-web`](hd-web/) | Private report ingestion and viewing application | Next.js, TypeScript, Prisma |

The workspace repository does not build or release either project. Make code
changes in the relevant submodule and use this repository for shared
documentation, workspace configuration, and recording submodule revisions.

## Clone the workspace

Clone with its submodules:

```sh
git clone --recurse-submodules https://github.com/brendanwilliam/hd-workspace.git
```

If you already cloned the workspace, initialize the child repositories with:

```sh
git submodule update --init --recursive
```

To bring submodules to the commits recorded by the workspace after changing
branches, run the same `git submodule update --init --recursive` command.

## Working in a submodule

Each child directory has its own Git history, remotes, branches, instructions,
and pull requests. Run Git commands from that child repository unless you are
intentionally updating the workspace pointer.

```sh
cd hd-obs
git status

cd ../hd-web
git status
```

After a child change is merged and you want the workspace to point at that
revision, check out the desired child commit, return to the workspace root,
commit the changed gitlink, and open a workspace pull request.

## Delivery flow

All three repositories use the same integration model:

```text
working branch → develop → main
```

Normal feature, fix, chore, and documentation pull requests target `develop`.
Open a separate promotion pull request from `develop` to `main` when the
integrated set is ready. Protected branches require pull requests, resolved
review threads, and signed commits.

Merging `hd-web` to `main` does not currently deploy a public application: the
web project is not connected to a domain.

## Signing commits

New commits and tags in the workspace and its submodules are signed with the
`brendanwilliam` GitHub SSH signing key. GitHub rules require signed commits on
every branch. Check a recent signature with:

```sh
git log -1 --show-signature
```

## Documentation

Shared product, API, data-contract, and implementation material is indexed in
[`docs/README.md`](docs/README.md). For code-specific setup, architecture, and
validation instructions, read the `README.md` and `AGENTS.md` in the relevant
submodule.

## Security and privacy

Hands Diff is designed around derived gameplay metrics rather than raw input
content. Do not add credentials, tokens, private user data, or keystroke
contents to this workspace or either submodule. Follow the more specific
privacy and Accessibility guidance in [`hd-obs/AGENTS.md`](hd-obs/AGENTS.md)
when working on input capture.
