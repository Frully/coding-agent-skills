# Python

## Preferred implementation order

1. Use `import-linter` to express package contracts and layer boundaries.
2. Use `LibCST` for file-placement or semantic import rules that contracts alone cannot express.

Do not rely on raw `grep` over `import` statements.

## Detection checklist

Read:

- `pyproject.toml`
- `setup.cfg`, `setup.py`, `requirements*.txt`, or Poetry config
- package layout under `src/` or top-level modules
- existing pytest structure and any architecture tests

Look for:

- domain/application/adapters layering
- Django or FastAPI conventions that shape module boundaries
- namespace packages or multiple installable packages in one repo

## Rule strategy

Use `import-linter` for:

- layered package contracts
- independence contracts between peer packages
- forbidden imports from outer layers into inner layers

Use `LibCST` when:

- placement depends on class or decorator patterns
- imports are dynamically aliased in ways that need AST normalization
- file placement must be enforced beyond package-level contracts

## Monorepo notes

For multi-package repos:

- infer installable package boundaries first
- distinguish shared utilities from business-domain packages
- avoid one global contract file when separate packages need separate rulesets

## False-positive controls

- separate test-only imports from production imports
- ignore migrations, settings, generated clients, and notebooks unless they are part of the architecture boundary
- prefer fully qualified module resolution from package metadata

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- a manifest-to-contract adapter or emitter
- `.importlinter` or `pyproject.toml` contract config
- a small `LibCST` checker only when necessary
- a task alias such as `check-architecture`
