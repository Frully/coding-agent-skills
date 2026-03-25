# Architecture Rules Format

Use this file when generating `architecture-rules.yaml`.

The goal of the manifest is not to replace language-native tooling. Its job is to record the inferred architecture in one stable, reviewable shape that downstream configs and helper scripts can derive from.
When the manifest is used as a source of truth, pair it with the adapter requirements in [architecture-adapter-contract.md](architecture-adapter-contract.md).

## Default schema

Use this structure unless the target repository already has a stronger native convention:

```yaml
version: 1
mode: single-repo | monorepo

summary:
  inferred_from:
    - manifests
    - import-graph
    - existing-tests
  user_confirmed:
    - "optional human-confirmed rule"
  notes:
    - "optional limitation or design note"

members:
  - id: example-member
    path: path/to/member
    languages: [ts]
    role: app | library | service | crate | package | module

zones:
  - id: example-zone
    member: example-member
    paths:
      - src/example/**
    tags:
      - layer:example
    description: Short human-readable meaning of the zone

rules:
  - id: example-rule
    kind: dependency | placement
    level: error | warn
    applies_to:
      members: [example-member]
      files:
        - src/**
    from:
      zones:
        - example-zone
    allow:
      zones:
        - shared-zone
    deny:
      zones:
        - forbidden-zone
    rationale: Why this boundary exists

exceptions:
  - id: example-exception
    rule: example-rule
    targets:
      - src/example/legacy_adapter.ts
    reason: Temporary legacy dependency
    expires_on: 2026-12-31

baseline:
  mode: off | report-only | block-new
  source: .architecture-baseline.json
```

## Field semantics

- `version`: manifest schema version for future compatibility.
- `mode`: whether the repository is a single project or a multi-member workspace.
- `summary.inferred_from`: evidence used during inference. Keep this concrete.
- `summary.user_confirmed`: only include items that were explicitly confirmed by the user.
- `members`: top-level units that may have independent boundaries, such as apps, packages, modules, services, projects, or crates.
- `zones`: semantic buckets used by the rules. A zone may map to a layer, feature family, platform slice, or public API surface.
- `rules`: the actual architecture constraints.
- `exceptions`: narrow, reviewable carve-outs. Prefer these over weakening the main rule.
- `baseline`: how to adopt the checker on a repository that already has violations.

## Authoring rules

- Keep `members` coarse and `zones` precise.
- Prefer a few strong zones over dozens of hyper-specific ones.
- Use `kind: dependency` for direction rules and `kind: placement` for "this file type belongs here" rules.
- Prefer rule shapes that can be compiled deterministically into native tooling.
- Put test-only allowances in separate rules or separate zones instead of weakening production rules.
- If the repository already has many violations, default `baseline.mode` to `block-new`.
- If there is no baseline need, set `baseline.mode` to `off`.
- Keep exceptions as narrow as possible and always include a reason.

## Selection guidance

Read the closest example before generating a new manifest:

- `example-js-ts-monorepo.yaml`: JS/TS workspace with app, feature, shared, and platform layers
- `example-python-service.yaml`: layered Python backend service
- `example-java-csharp-monorepo.yaml`: mixed JVM and .NET repository
- `example-go-rust-workspace.yaml`: service-oriented Go and Rust workspace

Use the example as a shape reference, not as a template to copy blindly.
