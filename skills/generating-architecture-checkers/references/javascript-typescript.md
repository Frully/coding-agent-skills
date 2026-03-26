# JavaScript and TypeScript

## Preferred implementation order

1. Use `dependency-cruiser` for package, layer, and cross-folder dependency rules.
2. Use `eslint` for import-shape rules that fit lint semantics cleanly.
3. Use `ts-morph` or the TypeScript Compiler API only when the needed rule depends on semantic information that the first two tools cannot express.

Do not start with custom AST code if `dependency-cruiser` already models the boundary correctly.

## Detection checklist

Read:

- `package.json`
- workspace markers such as `pnpm-workspace.yaml`, `turbo.json`, `nx.json`
- `tsconfig.json` and project references
- ESLint config files
- any existing dependency-cruiser config

Look for:

- path aliases that encode boundaries
- project references that already imply dependency direction
- Next.js, Vite, Node, or library package structure
- app versus package split in a monorepo

## Rule strategy

Use `dependency-cruiser` for:

- package-to-package dependency direction
- forbidden feature-to-feature imports
- allowed shared or platform modules
- circular dependency detection when it affects architecture

Use `eslint` for:

- local import restrictions tied to file placement
- test-only exceptions
- path alias misuse that is better enforced at the file level

Use custom AST only for cases like:

- rule depends on symbol-level semantics
- barrel indirection hides the real dependency from simpler config
- decorators or framework metadata materially affect allowed imports

## Monorepo notes

For workspaces:

- infer the package graph before local layer rules
- treat published or shared packages as public contracts unless the code suggests otherwise
- avoid duplicating package-boundary rules inside every app when one repo-level rule is enough

## False-positive controls

- resolve aliases before evaluating layer direction
- separate test, storybook, and tooling files from production enforcement
- exclude generated client code such as GraphQL or OpenAPI outputs

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- a small adapter or emitter that compiles the manifest into native rule config
- `.dependency-cruiser.cjs` or equivalent
- ESLint config additions or a repo-local custom rule package when required
- a package script such as `check-architecture`
