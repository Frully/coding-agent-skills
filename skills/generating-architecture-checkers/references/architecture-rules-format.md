# Architecture Rules Format

Use this file when generating `architecture-rules.yaml`.

The goal of the manifest is not to replace language-native tooling. Its job is to record the inferred architecture in one stable, reviewable shape that downstream configs and helper scripts can derive from.
When the manifest is used as a source of truth, pair it with the adapter requirements in [architecture-adapter-contract.md](architecture-adapter-contract.md).

## Manifest location rules

Do not default to the repository root unless the repository has no better established location.

Choose the manifest path in this order:

1. an existing config or checks directory already used by the repository
2. a stable member-local or runtime-local config location when the checker primarily applies to one member
3. the repository root as a fallback

Keep the file name `architecture-rules.yaml` unless the repository already has a stronger native naming convention.

## Default schema

Use this structure unless the target repository already has a stronger native convention:

```yaml
version: 1
mode: single-repo | monorepo
topology:
  kind: package-graph | runtime-graph | mixed

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

extensions:
  - id: example-content-rule
    kind: content
    engine: regex | ast | semantic
    owner: example-adapter
    applies_to:
      files:
        - src/**
    description: Optional supplement for manifest gaps
    rationale: Why a supplement is required

exceptions:
  - id: example-exception
    rule: example-rule
    targets:
      - src/example/legacy_adapter.ts
    reason: Temporary legacy dependency
    expires_on: 2026-12-31

baseline:
  mode: off | report-only | block-new
  path: .architecture-baseline.json
  resolve_from: repo-root
```

## Field semantics

- `version`: manifest schema version for future compatibility.
- `mode`: whether the repository is a single project or a multi-member workspace.
- `topology.kind`: whether the repository should be modeled primarily as a package graph, runtime graph, or mixed topology.
- `summary.inferred_from`: evidence used during inference. Keep this concrete.
- `summary.user_confirmed`: only include items that were explicitly confirmed by the user.
- `members`: top-level units that may have independent boundaries, such as apps, packages, modules, services, projects, or crates.
- `zones`: semantic buckets used by the rules. A zone may map to a layer, feature family, platform slice, or public API surface.
- `rules`: the actual architecture constraints.
- `extensions`: explicit supplements for rules that the core manifest cannot express as structural `dependency` or `placement` rules. Extensions are a safety valve, not a second rules engine. Keep them narrow, reviewable, and fewer in number than core rules.
- `exceptions`: narrow, reviewable carve-outs. Prefer these over weakening the main rule.
- `baseline`: how to adopt the checker on a repository that already has violations.

## Authoring rules

- Keep `members` coarse and `zones` precise.
- Prefer a few strong zones over dozens of hyper-specific ones.
- Use `kind: dependency` for direction rules and `kind: placement` for "this file type belongs here" rules.
- Prefer rule shapes that can be compiled deterministically into native tooling.
- Use `extensions` only when the rule cannot be expressed as a structural dependency or placement rule. If you find yourself adding more than three extensions, revisit whether the core rule set is modeled correctly first.
- Put test-only allowances in separate rules or separate zones instead of weakening production rules.
- If the repository already has many violations, default `baseline.mode` to `block-new`.
- If there is no baseline need, set `baseline.mode` to `off`.
- Keep exceptions as narrow as possible and always include a reason.
- Keep `baseline.path` repo-root relative unless there is a strong reason to do otherwise.
- Keep the manifest itself in the repository's natural config location instead of forcing it to the root.

## Selection guidance

Read the closest example before generating a new manifest:

- `example-js-ts-monorepo.yaml`: JS/TS workspace with app, feature, shared, and platform layers
- `example-python-service.yaml`: layered Python backend service
- `example-java-csharp-monorepo.yaml`: mixed JVM and .NET repository
- `example-go-rust-workspace.yaml`: service-oriented Go and Rust workspace
- `example-runtime-first-mixed.yaml`: runtime-first mixed-language repository with frontend, backend, and mobile members

Use the example as a shape reference, not as a template to copy blindly.
