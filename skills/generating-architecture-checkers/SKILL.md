---
name: generating-architecture-checkers
description: Generate repository-specific architecture checker scripts and rule configs when a user wants file layout and dependency boundaries enforced from the current codebase with AST-first, low-false-positive analysis.
---

# Generating Architecture Checkers

## Overview

Use this skill to generate architecture checking automation inside a target repository.

- inherit and extend the repository's existing gate before introducing new surfaces
- inspect the repository before choosing rules
- infer likely layers, package boundaries, and allowed dependency directions from current code
- prefer established AST or static-analysis tools from the target ecosystem
- generate one human-facing entrypoint such as `check-architecture`
- ask the user only when the codebase leaves a material architectural ambiguity

The output of this skill belongs in the target repository, not in the skill directory.

## When to use

Use this skill when:

- the user wants architecture checks generated for an existing repository
- the task is to enforce file placement, module boundaries, or dependency direction
- the repository may be single-package, multi-package, or a monorepo
- the user wants rules inferred from current code instead of hand-authoring everything
- false positives matter and the checker should prefer AST or semantic tooling over grep

## When not to use

Do not use this skill when:

- the task is to manually review architecture without generating checks
- the task is to refactor the codebase or auto-fix violations
- the task is generic lint, formatting, or import sorting
- the task is runtime wiring validation, deployment topology, or infrastructure architecture
- the repository language is outside the supported v1 set of `JS/TS`, `Python`, `Go`, `Java`, `C#`, `Dart`, and `Rust`

## Instructions

### 1. Detect repository shape first

Inspect the target repository before proposing tools or rules.

Before generating anything, inspect the current working tree and avoid rewriting unrelated local changes.

Read the root markers first:

- manifests such as `package.json`, `pnpm-workspace.yaml`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `*.csproj`, `pubspec.yaml`
- workspace and build files such as `turbo.json`, `nx.json`, Gradle settings, solution files, and cargo workspace config
- existing rule files such as ESLint configs, dependency-cruiser configs, `importlinter` config, `ArchUnit` tests, `NetArchTest` tests, custom lints, or repo-local architecture docs
- existing gate surfaces such as task runners, CI entrypoints, local verification commands, aggregated checks, and architecture-related wrappers already used by the repository

Determine:

- supported languages present
- whether the repo is single-project or monorepo/workspace
- package, app, crate, project, or module boundaries
- whether the repository behaves like a package graph, a runtime graph, or a mixed topology
- whether the repo already has an architecture enforcement mechanism that should be extended instead of replaced

Read reference files in phases to keep context lean:

**Phase A — Detection and inference** (read before step 2):

- [references/common-strategy.md](references/common-strategy.md) — always
- the language reference file(s) that match the detected stack — only those languages

**Phase B — Manifest authoring** (read only when you are about to generate `architecture-rules.yaml`):

- [references/architecture-rules-format.md](references/architecture-rules-format.md)
- the closest example file from the selection guidance table

**Phase C — Adapter and execution** (read only when you are about to write checker code):

- [references/architecture-adapter-contract.md](references/architecture-adapter-contract.md)
- [references/baseline-format.md](references/baseline-format.md) — only if `baseline.mode` is not `off`

Do not read Phase B or C files during detection. This keeps context available for the code you actually need to generate.

### 2. Infer architecture before asking

Infer the intended structure from implemented code, not from directory names alone.

Use multiple signals together:

- directory layout and naming
- import or use graph
- package manifests and module declarations
- existing tests or rule files
- repeated dependency direction patterns already present in the codebase
- framework conventions that are clearly in use

Infer the lightest rule set that matches the codebase:

- runtime or member boundaries first when the repo is organized around deployable runtimes or services
- package or workspace boundaries
- layer or feature boundaries inside each package
- shared or platform modules that may be imported broadly
- forbidden dependency directions such as UI to infra, domain to adapters, or feature-to-feature imports

Do not assume one named architecture style unless the repository clearly exhibits it.

### 3. Evaluate architecture health

After inferring the current structure, check whether that structure is itself reasonable before protecting it with rules.

Scan for common anti-patterns:

- **Circular dependencies** — two or more zones or members that import each other, making it impossible to determine a clear dependency direction
- **Layer inversion** — a lower layer (e.g. domain) importing a higher layer (e.g. adapters, infra, HTTP, database)
- **Hub coupling** — one module imported by nearly every other module while also importing many of them back, creating a single point of fragility
- **Boundary erosion** — a zone labeled `shared` or `platform` that has accumulated business-specific logic from multiple features
- **Feature entanglement** — two or more feature zones with heavy mutual imports that should be isolated

When anti-patterns are found:

- report each issue to the user with concrete evidence (which modules, which import edges)
- propose a corrected target architecture that resolves the anti-pattern
- state the default correction you would apply if the user does not respond
- generate checks against the corrected target, not against the broken status quo
- record the existing violations as baseline so the checker does not block current code immediately but prevents further regression

When the codebase is healthy or has only minor issues, skip this step silently and proceed.

### 4. Ask only on high-impact ambiguity

Ask the user only when the architecture cannot be inferred safely enough to generate low-noise checks.

Ask when:

- the same codebase strongly matches two different boundary models
- a shared module could reasonably be either platform infrastructure or domain logic
- current dependencies conflict badly enough that you cannot tell intended rules from historical debt
- the user names a target architecture and the code clearly disagrees
- an anti-pattern from step 3 has multiple plausible corrections

When asking, present the concrete ambiguity and the default you would choose if unanswered.

### 5. Choose the checker implementation per language

Prefer ecosystem-native AST or semantic tooling first. Reuse mature tools when they can express the rule accurately. Generate custom AST checks only when off-the-shelf tools cannot express the needed boundary.

Choose the enforcement level before picking tools:

- Level 1: minimum viable enforcement through one manifest, one adapter, and one hook into the existing gate
- Level 2: native-tool enforcement when the repository already has the dependency surface or the adoption cost is low
- Level 3: targeted semantic or content checks only for gaps that materially matter and cannot be expressed by the lower levels

Use this decision guide:

- default to Level 1 when the repository has no existing architecture tooling and the immediate goal is to land a first check quickly
- prefer Level 2 when the repository already depends on a supported native tool or adding one is a single-line manifest change
- add Level 3 supplements only when a specific rule requires symbol-level, content, or semantic analysis that Levels 1–2 cannot express — and document each supplement separately

When repository constraints and ideal native-tool choice conflict, prioritize the smallest version that integrates cleanly into the existing gate and document the upgrade path.

Default language order:

- `JS/TS`: dependency-cruiser, ESLint, then `ts-morph` or TypeScript Compiler API
- `Python`: import-linter, then `LibCST`
- `Go`: `go/packages` plus `go/ast`
- `Java`: `ArchUnit`
- `C#`: `NetArchTest`, then Roslyn if needed
- `Dart`: `custom_lint` plus analyzer AST
- `Rust`: `cargo metadata` plus `syn`

See the language-specific reference file before generating repository code.

### 6. Generate a uniform output contract

Always generate all of the following in the target repository:

- one entrypoint named or documented as `check-architecture`, preferably by extending an existing gate surface instead of inventing a parallel one
- one rule manifest, using a repository-appropriate `architecture-rules.yaml` location instead of always writing to the root
- one adapter layer that translates the manifest into language-native configs, tests, or checker code
- the smallest native configs, tests, or helper checkers required for the selected enforcement level
- a short report that separates inferred rules, user-confirmed rules, explicit exceptions, gate integration, and enforcement limits

Choose the manifest location from the repository structure:

- prefer an existing config, tooling, or checks directory when the repository already has one
- prefer a member-local or runtime-local location when the checker primarily applies to one runtime or member
- use the repository root only when there is no better established location

Treat the chosen `architecture-rules.yaml` file as the repository-level source of truth whenever you introduce it. The generated checker must derive from that manifest, not silently diverge from it.

Prefer the repository's existing task system for the entrypoint:

- `npm` / `pnpm` / `yarn` scripts
- `make`
- Gradle tasks
- `dotnet` commands
- `cargo` aliases
- repo-local task runners already in use

Do not force a new wrapper tool when the repo already has a natural command surface.
Keep entrypoint and documentation edits minimal when the working tree already contains unrelated local changes.

### 7. Compile the manifest into native checks

When the target repository uses `architecture-rules.yaml`, generate an explicit translation layer from the manifest into the native checker surface.

The translation layer may be:

- a small code generator script
- a deterministic config emitter
- a test helper that loads the manifest and constructs assertions
- a thin runtime that reads the manifest directly if the ecosystem supports it cleanly

The translation layer must:

- map `members`, `zones`, `rules`, `exceptions`, and `baseline` into native enforcement
- fail fast on unsupported rule shapes instead of silently ignoring them
- document which manifest fields are enforced by which native tool
- keep the generated native configuration reproducible from the manifest

If a native tool cannot express a manifest rule exactly, either:

- generate a custom AST or semantic check for just that gap, or
- reject that rule shape and state the limitation explicitly

Do not claim full enforcement if part of the manifest is only advisory.
If you add manifest-declared extensions for content or semantic gaps, list them explicitly in the final report and keep them visibly separate from the core structural rules.

Extensions guardrail: the `extensions` section is a safety valve, not a second rules engine. Apply these limits:

- do not add an extension when the same boundary can be expressed as a `dependency` or `placement` rule
- keep the total number of extensions smaller than the total number of core rules
- each extension must name an explicit `engine` and a narrow `applies_to` scope
- if you find yourself adding more than three extensions, revisit whether the core rule set is modeled correctly first

### 8. Control false positives explicitly

Do not generate a checker that relies on naive path matching unless the repository is too small or too simple to justify stronger analysis.

Default safeguards:

- exclude generated code, vendored code, build output, and lockfiles
- handle test-only imports separately from production code
- treat migration, tooling, and example directories as separate rule zones when needed
- prefer semantic import resolution over raw string matching
- if the repo already has many violations, create a baseline or incremental gating strategy instead of blocking every historical issue immediately

When you must fall back from AST to a simpler approach, state the limitation in the generated notes.

### 9. Validate before handing off

Validate the generated checker in the target repository.

At minimum:

- confirm the manifest parses cleanly
- confirm the adapter layer can compile or emit the native checks from the manifest
- confirm the entrypoint runs through the repository's existing gate surface
- confirm one known-good path passes
- confirm one deliberate or existing violation is reported
- confirm each enforced member or runtime has at least one real rule under test
- confirm monorepo or runtime-graph boundaries are checked at the correct scope
- confirm one false-positive regression case does not report

When practical, perform a round-trip validation:

- add or simulate one manifest rule
- regenerate the native checker artifacts
- verify the expected violation surface changes accordingly

If the repository lacks a runnable environment, still return the generated artifacts and clearly state what could not be executed.

### 10. Degrade gracefully when conditions are incomplete

Not every repository provides a full toolchain or runnable environment. When a step cannot be completed, produce the best partial result instead of aborting.

Degradation priorities:

- if native tools are unavailable or cannot be installed, fall back to a repo-local adapter at Level 1 and document the upgrade path
- if the runtime environment cannot execute the checker, return all generated artifacts with a clear list of what was validated statically versus what requires a live run
- if a language in a mixed repo is outside the supported v1 set, generate checks for the supported languages only and note the uncovered member in the report
- if the import graph cannot be resolved reliably, prefer conservative rules with wider allowlists over aggressive rules that will produce false positives
- if the existing gate surface is unclear, generate a standalone `check-architecture` script and note the recommended integration point

Always state what was skipped and why in the final report so the user can close the gap later.

## Examples

Input: "Generate architecture checks for this Next.js pnpm monorepo. Infer package boundaries and feature/shared rules from the current apps and packages."

Output:

```text
- Detect pnpm workspace and package graph
- Use dependency-cruiser for package boundaries and ESLint for local import restrictions
- Generate architecture-rules.yaml and a check-architecture npm script
- Ask only if a package looks both shared-platform and business-domain
```

Input: "Create architecture enforcement for this Python service using the existing domain/application/adapters layout."

Output:

```text
- Infer contracts from current imports
- Generate import-linter config plus targeted LibCST checks for file-placement rules
- Add architecture-rules.yaml and a check-architecture command
```

Input: "This repo is half Java and half C#. Figure out the existing layering and generate checks."

Output:

```text
- Split inference by project boundary
- Generate ArchUnit tests for Java modules and NetArchTest coverage for C# projects
- Provide one top-level check-architecture entrypoint that runs both
```

Input: "Generate checks, but ask me if the shared package should be allowed to depend on billing."

Output:

```text
Question: The current graph supports two plausible interpretations for shared/.
Default if unanswered: treat shared/ as platform-only and forbid billing imports into it.
```

### End-to-end walkthrough

Input: "Add architecture checks to this Go service that uses domain/application/adapters layout."

Execution flow:

```text
Phase A — Detection and inference
  1. Read go.mod → single module, Go 1.22
  2. Read common-strategy.md + go.md
  3. Scan directory tree → cmd/server/, internal/domain/, internal/application/, internal/adapters/
  4. Sample imports → domain has zero internal imports, application imports domain only,
     adapters imports application and domain, cmd imports adapters
  5. Infer topology: single-repo, package-graph
  6. Infer 4 zones: domain, application, adapters, entrypoint
  7. Health check → no circular deps, no layer inversion, structure is clean → skip
  8. No ambiguity → no user question needed
  9. Enforcement level: Level 1 (no existing arch tooling, land first check quickly)

Phase B — Manifest authoring
  10. Read architecture-rules-format.md + example-python-service.yaml (closest shape)
  11. Generate architecture-rules.yaml in tools/architecture/

Phase C — Adapter and execution
  12. Read architecture-adapter-contract.md
  13. Generate tools/architecture/check.go — small go/packages adapter
  14. Add `check-architecture` target to existing Makefile
  15. Baseline mode: off (no existing violations found)

Validation
  16. go vet tools/architecture/check.go → passes
  17. make check-architecture → passes (0 violations)
  18. Add test import of adapters into domain → violation reported ✓
  19. Remove test import → back to 0 violations ✓

Report
  - gate-integration: Makefile target `check-architecture`
  - health-issues: none
  - native-enforced: none (Level 1, repo-local adapter)
  - adapter-enforced: domain-purity, application-boundary, adapters-direction
  - heuristic-or-partial: none
  - blind-spots: symbol-level re-exports not checked
  - upgrade-path: migrate to go/analysis pass for IDE integration
```

## Additional files

- `references/common-strategy.md`: repository detection order, inference rules, monorepo handling, baseline strategy, and exception recording
- `references/architecture-rules-format.md`: canonical `architecture-rules.yaml` shape, field semantics, and example selection guidance
- `references/architecture-adapter-contract.md`: required translation contract from `architecture-rules.yaml` into executable native checks
- `references/baseline-format.md`: baseline JSON shape, path resolution, identity fields, and `block-new` comparison rules
- `references/example-js-ts-monorepo.yaml`: example rule manifest for a `JS/TS` workspace with app, feature, shared, and platform boundaries
- `references/example-python-service.yaml`: example rule manifest for a layered `Python` service
- `references/example-java-csharp-monorepo.yaml`: example rule manifest for a mixed `Java` and `C#` repository
- `references/example-go-rust-workspace.yaml`: example rule manifest for a `Go` plus `Rust` multi-service workspace
- `references/example-runtime-first-mixed.yaml`: example rule manifest for a runtime-first mixed-language repository
- `references/javascript-typescript.md`: `JS/TS` implementation order and AST fallback rules
- `references/python.md`: `Python` implementation order and contract inference guidance
- `references/go.md`: `Go` package analysis and checker generation guidance
- `references/java.md`: `Java` layer enforcement with `ArchUnit`
- `references/csharp.md`: `C#` project-boundary enforcement with `NetArchTest` and Roslyn fallback
- `references/dart.md`: `Dart` and Flutter analyzer-based enforcement guidance
- `references/rust.md`: `Rust` workspace and crate-boundary enforcement guidance
