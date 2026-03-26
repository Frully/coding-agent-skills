---
name: generating-architecture-checkers
description: Generate repository-specific architecture checker scripts and rule configs when a user wants file layout and dependency boundaries enforced from the current codebase with AST-first, low-false-positive analysis.
---

# Generating Architecture Checkers

## Overview

Use this skill to generate architecture checking automation inside a target repository.

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

Read the root markers first:

- manifests such as `package.json`, `pnpm-workspace.yaml`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle*`, `*.csproj`, `pubspec.yaml`
- workspace and build files such as `turbo.json`, `nx.json`, Gradle settings, solution files, and cargo workspace config
- existing rule files such as ESLint configs, dependency-cruiser configs, `importlinter` config, `ArchUnit` tests, `NetArchTest` tests, custom lints, or repo-local architecture docs

Determine:

- supported languages present
- whether the repo is single-project or monorepo/workspace
- package, app, crate, project, or module boundaries
- whether the repo already has an architecture enforcement mechanism that should be extended instead of replaced

Read [references/common-strategy.md](references/common-strategy.md) before making any inference-heavy decision. Then read only the language reference files that match the detected stack.
If you are about to generate `architecture-rules.yaml`, also read [references/architecture-rules-format.md](references/architecture-rules-format.md) and the closest example file.
If you are generating executable checks from that manifest, also read [references/architecture-adapter-contract.md](references/architecture-adapter-contract.md) before writing any checker code.

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

- package or workspace boundaries
- layer or feature boundaries inside each package
- shared or platform modules that may be imported broadly
- forbidden dependency directions such as UI to infra, domain to adapters, or feature-to-feature imports

Do not assume one named architecture style unless the repository clearly exhibits it.

### 3. Ask only on high-impact ambiguity

Ask the user only when the architecture cannot be inferred safely enough to generate low-noise checks.

Ask when:

- the same codebase strongly matches two different boundary models
- a shared module could reasonably be either platform infrastructure or domain logic
- current dependencies conflict badly enough that you cannot tell intended rules from historical debt
- the user names a target architecture and the code clearly disagrees

When asking, present the concrete ambiguity and the default you would choose if unanswered.

### 4. Choose the checker implementation per language

Prefer ecosystem-native AST or semantic tooling first. Reuse mature tools when they can express the rule accurately. Generate custom AST checks only when off-the-shelf tools cannot express the needed boundary.

Default language order:

- `JS/TS`: dependency-cruiser, ESLint, then `ts-morph` or TypeScript Compiler API
- `Python`: import-linter, then `LibCST`
- `Go`: `go/packages` plus `go/ast`
- `Java`: `ArchUnit`
- `C#`: `NetArchTest`, then Roslyn if needed
- `Dart`: `custom_lint` plus analyzer AST
- `Rust`: `cargo metadata` plus `syn`

See the language-specific reference file before generating repository code.

### 5. Generate a uniform output contract

Always generate all of the following in the target repository:

- one human-facing entrypoint named or documented as `check-architecture`
- one rule manifest, defaulting to `architecture-rules.yaml` unless the repository already has a stronger native convention
- one adapter layer that translates the manifest into language-native configs, tests, or checker code
- the language-specific configs, tests, or helper checkers required to enforce the rules
- a short note that separates inferred rules, user-confirmed rules, and explicit exceptions

Treat `architecture-rules.yaml` as the repository-level source of truth whenever you introduce it. The generated checker must derive from the manifest, not silently diverge from it.

Prefer the repository's existing task system for the entrypoint:

- `npm` / `pnpm` / `yarn` scripts
- `make`
- Gradle tasks
- `dotnet` commands
- `cargo` aliases
- repo-local task runners already in use

Do not force a new wrapper tool when the repo already has a natural command surface.

### 6. Compile the manifest into native checks

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

### 7. Control false positives explicitly

Do not generate a checker that relies on naive path matching unless the repository is too small or too simple to justify stronger analysis.

Default safeguards:

- exclude generated code, vendored code, build output, and lockfiles
- handle test-only imports separately from production code
- treat migration, tooling, and example directories as separate rule zones when needed
- prefer semantic import resolution over raw string matching
- if the repo already has many violations, create a baseline or incremental gating strategy instead of blocking every historical issue immediately

When you must fall back from AST to a simpler approach, state the limitation in the generated notes.

### 8. Validate before handing off

Validate the generated checker in the target repository.

At minimum:

- confirm the manifest parses cleanly
- confirm the adapter layer can compile or emit the native checks from the manifest
- confirm the entrypoint runs
- confirm one known-good path passes
- confirm one deliberate or existing violation is reported
- confirm monorepo package boundaries are checked at the correct scope

When practical, perform a round-trip validation:

- add or simulate one manifest rule
- regenerate the native checker artifacts
- verify the expected violation surface changes accordingly

If the repository lacks a runnable environment, still return the generated artifacts and clearly state what could not be executed.

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

## Additional files

- `references/common-strategy.md`: repository detection order, inference rules, monorepo handling, baseline strategy, and exception recording
- `references/architecture-rules-format.md`: canonical `architecture-rules.yaml` shape, field semantics, and example selection guidance
- `references/architecture-adapter-contract.md`: required translation contract from `architecture-rules.yaml` into executable native checks
- `references/example-js-ts-monorepo.yaml`: example rule manifest for a `JS/TS` workspace with app, feature, shared, and platform boundaries
- `references/example-python-service.yaml`: example rule manifest for a layered `Python` service
- `references/example-java-csharp-monorepo.yaml`: example rule manifest for a mixed `Java` and `C#` repository
- `references/example-go-rust-workspace.yaml`: example rule manifest for a `Go` plus `Rust` multi-service workspace
- `references/javascript-typescript.md`: `JS/TS` implementation order and AST fallback rules
- `references/python.md`: `Python` implementation order and contract inference guidance
- `references/go.md`: `Go` package analysis and checker generation guidance
- `references/java.md`: `Java` layer enforcement with `ArchUnit`
- `references/csharp.md`: `C#` project-boundary enforcement with `NetArchTest` and Roslyn fallback
- `references/dart.md`: `Dart` and Flutter analyzer-based enforcement guidance
- `references/rust.md`: `Rust` workspace and crate-boundary enforcement guidance
