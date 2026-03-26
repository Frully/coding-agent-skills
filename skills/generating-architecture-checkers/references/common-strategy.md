# Common Strategy

Use this file for repository-wide decisions before reading any language-specific reference.

## Detection order

1. Read root manifests and workspace markers.
2. Read package or project manifests under each workspace member.
3. Read existing lint, test, architecture rule, and gate-integration surfaces.
4. Check whether the working tree already has unrelated local changes and keep later edits minimal if it does.
5. Sample representative source files from each major package, runtime, or layer.
6. Build a dependency picture from imports, module declarations, or project references.

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

- runtime or deployable-member boundaries first when the repository is organized around distinct runtimes
- workspace package boundaries first
- then module or layer boundaries inside each package
- then file-placement rules only when the repository structure depends on them

Do not overfit one or two outlier files.

## Architecture health check

After inferring the current structure, evaluate whether the structure itself is sound before generating rules to protect it. Protecting a broken architecture locks in the damage.

### Anti-patterns to detect

| Anti-pattern | Signal | Severity |
|---|---|---|
| Circular dependency | Two or more zones or members import each other | high |
| Layer inversion | A lower layer (domain) imports a higher layer (adapters, infra, HTTP, DB) | high |
| Hub coupling | One module is imported by most other modules and also imports many of them back | medium |
| Boundary erosion | A zone labeled `shared` or `platform` contains business-specific logic from multiple features | medium |
| Feature entanglement | Two or more feature zones with heavy mutual imports that should be isolated | medium |

### How to respond

- **High severity**: always report to the user with concrete evidence (which modules, which edges). Propose a corrected target architecture and state the default correction you would apply if unanswered.
- **Medium severity**: report to the user when the anti-pattern affects three or more modules. For isolated cases, note in the report but generate rules based on the corrected direction.
- **No issues found**: skip this step silently and proceed.

### Rule generation after correction

When anti-patterns are found and a corrected target is chosen:

- generate rules against the corrected target architecture, not the broken status quo
- record existing violations as baseline (`block-new` mode) so current code is not immediately blocked
- include a `health-issues` section in the final report listing each detected anti-pattern, the correction applied, and the number of baseline violations it produced

### Ambiguity during correction

When an anti-pattern has multiple plausible corrections (e.g., a circular dependency could be broken in either direction), escalate to the user via the ambiguity step instead of guessing.

## Topology strategy

Treat multi-member repositories as one of these topologies:

- `package-graph`: packages or libraries are the primary top-level model
- `runtime-graph`: deployable runtimes, apps, services, or clients are the primary model
- `mixed`: the repo needs both runtime-first and package-first boundaries

For `runtime-graph` and `mixed` repositories:

- identify deployable runtimes or independently shipped members first
- model each runtime as a top-level `member`
- infer intra-runtime layers only after runtime boundaries are clear
- keep shared libraries subordinate to runtime/member ownership instead of forcing a pure package graph

Treat monorepos and workspaces as two levels of enforcement:

1. Repository-level boundaries between apps, packages, crates, services, or projects
2. Intra-project boundaries inside each member

For monorepos:

- derive the workspace graph first
- identify leaf apps versus shared libraries
- detect cross-package edges that already behave like public APIs
- avoid generating intra-package rules that contradict workspace-level contracts

If a package serves both platform and domain concerns, ask the user instead of guessing.

## Existing gate strategy

Before creating a new command surface, detect how the repository already runs verification.

Look for:

- local developer verification entrypoints
- task runners and orchestration layers
- CI or automation job entrypoints
- aggregated check surfaces that already combine lint, test, or smoke checks

Default behavior:

- extend an existing gate if one is already present
- keep the integration local and minimal
- add a compatibility wrapper only when changing the primary gate would otherwise break local or CI workflows

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
- ignore lockfiles and non-code static assets unless a rule explicitly targets them
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
Read [baseline-format.md](baseline-format.md) before choosing any baseline file shape or comparison logic.

## Enforcement levels

Choose the lightest level that safely integrates into the repository.

- Level 1: one manifest, one adapter, one hook into the existing gate
- Level 2: native-tool configs or tests when the repository already has the right dependency surface or the adoption cost is low
- Level 3: targeted content or semantic supplements for gaps that the lower levels cannot express

Do not jump to Level 3 unless Levels 1 and 2 are insufficient for a real rule.

### Decision matrix

| Signal | Start at |
|---|---|
| No existing architecture tooling; first-time adoption | Level 1 |
| Repository already depends on a supported native tool | Level 2 |
| Adding the native tool is a single manifest-line change and aligns with existing dev workflow | Level 2 |
| All inferred rules are expressible as dependency or placement rules | stay at current level |
| A specific rule requires symbol-level, decorator, or content analysis | add Level 3 supplement for that rule only |
| Repository has tight CI budgets or minimal dev tooling | Level 1, document upgrade path |
| Mixed-language repo where one language has native tooling and the other does not | Level 2 for the supported language, Level 1 for the other |

When the decision is borderline, prefer the lower level and document the upgrade path in the final report.

## Native tool decision matrix

Choose in this order:

- if the goal is fast, low-risk integration into an existing gate, prefer a small repo-local adapter first
- if the repository already has the relevant native tool or the incremental adoption cost is low, prefer the native tool
- if both options are viable, choose the one that keeps the smallest diff and cleanest gate integration
- if you deliver a repo-local adapter first, document the native-tool upgrade path in the final report

## Output contract

Always return or generate:

- one human-facing `check-architecture` entrypoint
- one rule manifest placed in the repository's most natural config location, usually named `architecture-rules.yaml`
- one adapter layer that turns the manifest into executable native checks
- language-native configs, tests, or helper checkers
- one short report covering gate integration, inferred rules, user-confirmed choices, exceptions, and enforcement limits

Prefer native locations and task systems already present in the target repository.
Prefer an existing config or checks directory over the repository root when choosing the manifest location.
For runtime-first or member-local enforcement, prefer the nearest stable member-local config location.
Use [architecture-rules-format.md](architecture-rules-format.md) as the default manifest schema unless the target repository already has a stronger native rule format.
Use [architecture-adapter-contract.md](architecture-adapter-contract.md) whenever the manifest is intended to drive executable checks.

## Final validation

Before handoff:

- run or smoke-test the manifest adapter layer
- run the generated checker if the environment is available
- verify at least one real rule per enforced member or runtime
- verify one expected pass case
- verify one expected failure case
- verify one false-positive regression case does not trigger
- confirm the command surface is stable enough for local use and CI
