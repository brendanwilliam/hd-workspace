# Documentation Index

This directory holds shared design material, API examples, data contracts, and
implementation notes for Hands Diff. The submodule repositories remain the
source of truth for code-level documentation.

## Product and implementation

- [`v2.md`](v2.md): current Hands Diff v2 design overview.
- [`v2-implementation-status.md`](v2-implementation-status.md): implemented
  and planned v2 work.
- [`v2-draft1.md`](v2-draft1.md) and [`v2-draft2.md`](v2-draft2.md): earlier
  design exploration and decisions.
- [`v2-telemetry-and-retention.md`](v2-telemetry-and-retention.md): telemetry,
  privacy, and retention considerations.

## Reports, reconciliation, and inputs

- [`v2-report-contract.md`](v2-report-contract.md): report payload contract.
- [`v2-binding-contract.md`](v2-binding-contract.md): input binding contract.
- [`v2-reconciliation.md`](v2-reconciliation.md): reconciliation flow and
  outcomes.

## Riot API references

- [`match-v5.md`](match-v5.md) and [`match-v5-timeline.md`](match-v5-timeline.md):
  Match V5 analysis and timeline notes.
- The matching PDFs preserve shareable rendered versions of those references.
- [`raw-data/`](raw-data/): captured fixtures and response examples used to
  inform contracts and parsing. See [`raw-data/README.md`](raw-data/README.md)
  for provenance and handling notes.

## Keeping documentation current

Update the document closest to the decision being made. When a behavior
changes in `hd-obs` or `hd-web`, update that repository's own documentation
first; add or revise a workspace document only when the decision spans both
projects or is useful as a shared reference.
