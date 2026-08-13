# Repository Guidelines

This workspace contains two independent Git repositories. Run Git, build, and
test commands from the relevant project directory—not from this workspace root.
Read the project-specific `AGENTS.md` before changing either repository; it
overrides this guide when instructions differ.

Repository-owned agent workflows and delivery skills are versioned with each
project. Use `hd-obs/skills/obs-github-issues` for OBS issues and
`hd-web/skills/hands-diff-github-issues` for Hands Diff issues; install the
relevant repository skills with that repository's installer when needed.

## Project Structure & Module Organization

- `hd-obs/` is the macOS Input Activity OBS plugin. Its C++ and
  Objective-C++ code lives in `src/`; OBS source implementations are in
  `src/sources/`; tests are in `tests/`; packaged assets and locales are in
  `data/`; and CMake support is in `cmake/`.
- `hd-web/` is a Next.js application. Keep application code in `src/`,
  static files in `public/`, and Prisma schema/configuration in `prisma/`.

## Build, Test, and Development Commands

From `hd-obs/`:

```sh
cmake --preset macos-ci          # configure the CI-equivalent build
cmake --build --preset macos-ci  # compile plugin and tests
```

For local macOS OBS testing, build `RelWithDebInfo` from the checked-out `hd-obs/` branch and verify that OBS loads
the development symlink at
`~/Library/Application Support/obs-studio/plugins/hd-obs.plugin`, pointing to
`hd-obs/build_macos/RelWithDebInfo/hd-obs.plugin`. Do not use an `input-activity.plugin` link as a substitute: it
can coexist with a stale `hd-obs.plugin` that OBS loads instead. Before replacing a regular installed bundle, move it
to a timestamped backup with user approval; do not leave duplicate loadable bundles with the same plugin identifier.

From `hd-web/`:

```sh
npm run dev      # start Next.js development server
npm run lint     # run ESLint
npm run build    # create a production build
```

## Coding Style & Naming Conventions

Follow nearby code and keep changes scoped to one project. In the OBS plugin,
format edited C, C++, and Objective-C++ with `clang-format 19`; use `gersemi`
for CMake and YAML. Use project-root-relative internal includes such as
`input/input_data.hpp`, never `../` paths. Keep implementation files grouped
by responsibility under `src/sources/`. In the web app, follow TypeScript,
React, and ESLint conventions already configured by Next.js.

## Testing Guidelines

Add or update focused OBS tests in `hd-obs/tests/` (for example,
`*_test.cpp`) when behavior is testable. Run the CI-equivalent configure and
build before handoff, and manually exercise affected OBS sources. For web
changes, run `npm run lint` and `npm run build`; test the affected UI locally.

## Commit & Pull Request Guidelines

Each project has separate history and branches. For `hd-obs`, create
`feature/<kebab-title>`, `fix/<kebab-title>`, or `chore/<kebab-title>` from
`develop`, and target normal pull requests to `develop`; promote to `main` in
a separate PR. Use focused Conventional Commit subjects such as `feat:`,
`fix:`, `docs:`, or `test:`. Describe the change, testing performed, linked
issue, and screenshots for user-visible UI changes. Do not commit credentials
or generated build directories.
