# Architecture Adapter Contract

Use this file when the target repository includes `architecture-rules.yaml` and you need the generated checks to execute accurately from that manifest.

## Goal

Treat `architecture-rules.yaml` as the repository-level architecture spec and generate a thin adapter layer that compiles the manifest into language-native enforcement.

The adapter layer is required whenever the native tool does not already consume the manifest directly.

## Required contract

The generated implementation must have these stages:

1. Parse the manifest.
2. Validate schema and required references.
3. Resolve `members` and `zones` into concrete files, packages, namespaces, crates, or projects.
4. Translate each `rule` into one or more native checks.
5. Apply `exceptions` and `baseline`.
6. Expose one stable entrypoint through `check-architecture`.

Do not skip any stage silently.

## Manifest features that must compile

These fields are mandatory to support when present:

- `members`
- `zones`
- `rules.id`
- `rules.kind`
- `rules.level`
- `rules.applies_to`
- `rules.from`
- `rules.allow`
- `rules.deny`
- `rules.rationale`
- `exceptions`
- `baseline`

If a target tool cannot enforce one of these fields directly, the adapter must either:

- generate supplemental checker code for the missing part, or
- fail with a clear unsupported-rule error

Ignoring fields is not allowed.

## Resolution rules

Resolve in this order:

1. `members` to repo-relative ownership boundaries
2. `zones.paths` to concrete file or package sets
3. `rules.applies_to` to the subset of files or members under enforcement
4. `from`, `allow`, and `deny` to concrete dependency edges or placement targets

Reject ambiguous matches when a zone expands outside its intended member boundary.

## Dependency rule semantics

For `kind: dependency`:

- `from.zones` defines the origin scope
- `allow.zones` defines the only permitted outgoing dependency targets when non-empty
- `deny.zones` defines explicitly forbidden targets
- if both `allow` and `deny` are present, `deny` wins for overlapping targets

Never infer additional allowed targets that are absent from the manifest.

## Placement rule semantics

For `kind: placement`:

- `applies_to.files` is the candidate file set
- `from.zones` or `allow.zones` identifies the valid home zone
- `deny.zones` identifies forbidden locations or ownership zones

Use placement rules only for structural placement, not dependency direction.

## Exceptions and baseline

Exceptions must be applied after the main rule is resolved but before reporting final violations.

Baseline behavior:

- `off`: report all violations
- `report-only`: report current and new violations without failing the command
- `block-new`: allow baseline-listed historical violations but fail on new ones

If `block-new` is used, the adapter must compare current violations against the baseline source.

## Adapter outputs

The generated repository should contain:

- `architecture-rules.yaml`
- one adapter artifact or source directory that translates the manifest
- one or more native checker artifacts derived from that adapter
- one top-level `check-architecture` command

Prefer deterministic generation over handwritten duplicated configs.

## Per-language mapping guidance

- `JS/TS`: compile manifest zones into dependency-cruiser rules and ESLint restrictions; use `ts-morph` or TypeScript Compiler API only for rules not expressible in those configs
- `Python`: compile package-level dependency rules into `import-linter` contracts; use `LibCST` for placement and semantic gaps
- `Go`: compile manifest into a small Go checker using `go/packages` and `go/ast`; avoid a split brain between YAML and hardcoded package names
- `Java`: compile package and layer rules into `ArchUnit` tests generated from the manifest
- `C#`: compile assembly and namespace rules into `NetArchTest` tests; use Roslyn only for unsupported semantic gaps
- `Dart`: compile zones and dependency rules into analyzer-backed `custom_lint` rules or a thin adapter around analyzer AST
- `Rust`: compile crate and module rules into a small manifest-driven checker built on `cargo metadata` and `syn`

## Validation requirements

The generated implementation must prove that the adapter is wired correctly.

At minimum:

- manifest parsing test or smoke check
- one pass case
- one fail case
- one exception case if exceptions exist
- one baseline case if baseline mode is not `off`

When the repo already has native tests, integrate adapter validation there instead of inventing a second test harness.
