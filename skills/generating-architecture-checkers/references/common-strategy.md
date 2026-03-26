# Common Strategy

Use this file for repository-wide decisions before reading any language-specific reference.

## Detection order

1. Read root manifests and workspace markers.
2. Read package or project manifests under each workspace member.
3. Read existing lint, test, or architecture rule files.
4. Sample representative source files from each major package or layer.
5. Build a dependency picture from imports, module declarations, or project references.

Do not choose an architecture style before step 4 unless the repository already encodes it explicitly.

## Supported v1 scope

First-class support:

- `JS/TS`
- `Python`
- `Go`
- `Java`
- `C#`
- `Dart`
- `Rust`

Treat other languages as unsupported unless the user explicitly accepts a best-effort result.

## Inference rules

Infer boundaries from evidence, not preference.

Use these signals together:

- repeated import direction patterns
- package visibility boundaries
- naming patterns such as `domain`, `application`, `infra`, `shared`, `feature`, `ui`, `api`, `adapters`
- framework layout conventions that are consistently followed
- existing tests that already encode allowed interactions

Prefer the simplest rule set that explains the current codebase:

- workspace package boundaries first
- then module or layer boundaries inside each package
- then file-placement rules only when the repository structure depends on them

Do not overfit one or two outlier files.

## Monorepo strategy

Treat monorepos as two levels of enforcement:

1. Repository-level boundaries between apps, packages, crates, services, or projects
2. Intra-project boundaries inside each member

For monorepos:

- derive the workspace graph first
- identify leaf apps versus shared libraries
- detect cross-package edges that already behave like public APIs
- avoid generating intra-package rules that contradict workspace-level contracts

If a package serves both platform and domain concerns, ask the user instead of guessing.

## Ambiguity threshold

Ask the user only when the generated checker would likely be noisy or structurally wrong.

Material ambiguity includes:

- two plausible layer models with comparable evidence
- a shared module whose allowed dependencies materially change multiple packages
- circular dependencies that hide the intended direction
- a repo-wide statement from the user that conflicts with the code

When asking:

- describe the exact modules involved
- state the default you would choose
- explain the effect on generated rules

## False-positive controls

Apply these defaults unless the repository clearly wants otherwise:

- ignore generated sources, vendor trees, cache directories, and build outputs
- separate production checks from test-only imports
- treat tooling scripts, migrations, fixtures, and examples as special zones
- prefer resolved module graphs over raw path prefix checks
- use allowlists for well-known exception packages instead of broad disable rules

Do not ship a checker that is mostly regular expressions over import strings if stronger analysis is available in the ecosystem.

## Baseline strategy

If the repository already violates the inferred architecture in many places:

- generate a baseline or snapshot of current accepted violations
- block new violations first
- keep the baseline machine-readable and easy to reduce over time
- record every explicit exception with a reason

Do not default to all-or-nothing enforcement on a legacy codebase.

## Output contract

Always return or generate:

- one human-facing `check-architecture` entrypoint
- one rule manifest, usually `architecture-rules.yaml`
- one adapter layer that turns the manifest into executable native checks
- language-native configs, tests, or helper checkers
- one short note covering inferred rules, user-confirmed choices, and exceptions

Prefer native locations and task systems already present in the target repository.
Use [architecture-rules-format.md](architecture-rules-format.md) as the default manifest schema unless the target repository already has a stronger native rule format.
Use [architecture-adapter-contract.md](architecture-adapter-contract.md) whenever the manifest is intended to drive executable checks.

## Final validation

Before handoff:

- run or smoke-test the manifest adapter layer
- run the generated checker if the environment is available
- verify one expected pass case
- verify one expected failure case
- confirm the command surface is stable enough for local use and CI
