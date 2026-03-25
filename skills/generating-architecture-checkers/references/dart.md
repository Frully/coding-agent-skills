# Dart

## Preferred implementation order

1. Use `custom_lint` with analyzer AST support.
2. Extend with additional analyzer-based rules only when the standard custom lint surface is insufficient.

Prefer analyzer-driven checks, especially in Flutter projects.

## Detection checklist

Read:

- `pubspec.yaml`
- workspace or melos config if present
- package layout under `lib/`, `test/`, and feature folders
- existing analyzer and lint settings

Look for:

- Flutter feature/shared/core patterns
- package split in melos or multi-package repos
- presentation, application, domain, and data boundaries encoded by folder structure and imports

## Rule strategy

Use analyzer-based custom lint rules for:

- forbidden layer imports
- feature isolation
- file placement tied to Dart library structure
- package boundary checks in multi-package repos

Use custom semantic logic only when:

- exports obscure the real dependency edge
- generated code requires rule-aware filtering

## Monorepo notes

For melos or multi-package setups:

- infer package boundaries first
- treat public package APIs separately from internal `lib/src` rules
- avoid rules that break normal Flutter generated file conventions

## False-positive controls

- exclude generated `*.g.dart`, `*.freezed.dart`, and similar files
- separate test imports from production rules
- respect analyzer excludes already present in the repo

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- an adapter that maps manifest rules into analyzer-backed lint logic
- `custom_lint` rule package or repo-local lint setup
- a task or script documented as `check-architecture`
