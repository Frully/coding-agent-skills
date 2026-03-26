# Generating Architecture Checkers

[中文版](./README.zh.md) | English

You can spell out your architecture conventions in prompts or rule files, but AI coding agents can still violate them — coupling domain logic to infrastructure, letting dependencies creep across packages, dropping files in the wrong places. Documentation alone cannot constrain an agent. What it needs is a runnable check: break a boundary, get an error, fix it.

This skill infers architecture rules from existing code and generates a check command the agent can run after every change. When a boundary is violated, the agent immediately knows which rule failed and which file caused it, and fixes the issue on the spot. Architecture enforcement stops relying on documentation and manual review — it becomes an executable, self-correcting feedback loop.

For detailed implementation instructions, see [SKILL.md](./SKILL.md).

## When to use

- You want architecture checks generated for an existing repository
- You want rules inferred from current code instead of hand-authoring everything
- You need to enforce file placement, module boundaries, or dependency direction
- False positives matter and you prefer AST-based tooling over grep

This skill is **not** for manual architecture review, refactoring or auto-fixing violations, generic linting/formatting, or runtime wiring and deployment topology.

## How it works

1. **Detect** — reads manifests, workspace markers, existing lint surfaces, and gate integration
2. **Infer** — samples imports and directory structure to determine topology (package-graph, runtime-graph, or mixed)
3. **Health check** — scans for anti-patterns (circular dependencies, layer inversion, hub coupling, boundary erosion). When issues are found, reports them to the user and proposes a corrected target architecture. Rules are generated against the corrected target, with existing violations recorded as baseline
4. **Ask** — only when genuine ambiguity exists or an anti-pattern has multiple plausible corrections
5. **Generate** — produces manifest, adapter, native configs, and entrypoint at the appropriate enforcement level
6. **Validate** — confirms pass/fail/false-positive behavior before handing off

## What you get

The generated output follows a three-layer model:

1. **Manifest** (`architecture-rules.yaml`) — records inferred boundaries in one reviewable file
2. **Adapter** — translates the manifest into language-native tool configs, tests, or checker code
3. **Entrypoint** (`check-architecture`) — one command that runs the checks, integrated into the repository's existing gate

## Enforcement levels

| Level | When to use | What you get |
|-------|-------------|--------------|
| Level 1 | First-time adoption, no existing tooling | Manifest + repo-local adapter + gate hook |
| Level 2 | Native tool already present or trivial to add | Manifest + native tool configs/tests |
| Level 3 | Specific rule needs symbol/content analysis | Level 1 or 2 + targeted AST supplements |

## Supported languages

| Language | Primary tool | Fallback |
|----------|-------------|----------|
| JS/TS | dependency-cruiser, ESLint | ts-morph / TypeScript Compiler API |
| Python | import-linter | LibCST |
| Go | go/packages | go/ast |
| Java | ArchUnit | — |
| C# | NetArchTest | Roslyn |
| Dart | custom_lint + analyzer AST | — |
| Rust | cargo metadata | syn |

Mixed-language repositories are supported — each language gets its own native tooling, unified under a single entrypoint.

## Further reading

- [SKILL.md](./SKILL.md) — full implementation instructions and reference file index
- [references/common-strategy.md](references/common-strategy.md) — detection order, inference rules, decision matrices
- [references/architecture-rules-format.md](references/architecture-rules-format.md) — manifest schema and authoring guidance
- [references/architecture-adapter-contract.md](references/architecture-adapter-contract.md) — adapter translation contract
