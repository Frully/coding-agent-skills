# Rust

## Preferred implementation order

1. Use `cargo metadata` to understand workspace and crate relationships.
2. Use `syn` for crate-internal module or syntax-aware checks when crate boundaries are not enough.

Prefer Cargo-native graph data over path heuristics.

## Detection checklist

Read:

- `Cargo.toml`
- workspace members and dependency declarations
- crate layout under `src/`
- existing clippy, cargo, or custom tooling config

Look for:

- workspace crate boundaries
- library versus binary crates
- domain and infrastructure separation encoded by modules
- public API re-export patterns that may hide real edges

## Rule strategy

Use `cargo metadata` for:

- workspace graph construction
- crate dependency direction
- identifying shared or foundational crates

Use `syn` when:

- module-level boundaries matter inside a crate
- macro or re-export structure hides the actual import path
- file placement rules depend on declarations rather than crate names

## Monorepo notes

For workspaces:

- infer crate boundaries before module boundaries
- treat top-level workspace crates as the main contract surface
- keep binary-crate rules separate from reusable library-crate rules

## False-positive controls

- ignore generated code and build outputs
- treat tests and benches separately when they need broader imports
- account for re-exports before declaring a forbidden edge

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- a manifest-driven adapter or checker built on workspace metadata
- a small cargo-driven checker or crate-local validation module
- a cargo task or documented command surfaced as `check-architecture`
