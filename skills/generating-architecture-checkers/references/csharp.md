# C#

## Preferred implementation order

1. Use `NetArchTest` for assembly and namespace boundary checks.
2. Use Roslyn analyzers only when the needed rule requires finer semantic precision than `NetArchTest` can provide.

Do not start by writing ad hoc regex checks over `using` statements.

## Detection checklist

Read:

- `*.sln`
- `*.csproj`
- package references and project references
- namespace layout and any existing analyzer configuration

Look for:

- clean architecture or layered namespace conventions
- project reference direction between domain, application, infrastructure, and presentation
- test assemblies and shared tooling projects

## Rule strategy

Use `NetArchTest` for:

- allowed or forbidden assembly references
- namespace-based layer constraints
- type placement checks that map cleanly to assemblies or namespaces

Use Roslyn when:

- rules depend on symbol semantics or attributes
- partial classes or generators hide intent from assembly-only checks
- file placement and namespace constraints need richer diagnostics

## Monorepo notes

For multiple solutions or projects:

- infer project-reference boundaries first
- keep solution-level rules separate from per-project namespace rules
- avoid one giant analyzer if a smaller `NetArchTest` suite is sufficient

## False-positive controls

- separate test projects from production rules
- ignore generated code files and source generator outputs
- respect existing nullable, analyzer, and SDK conventions

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- a manifest-driven adapter for `NetArchTest` or Roslyn-backed checks
- `NetArchTest` test project updates or additions
- Roslyn analyzer project only when justified
- a `dotnet` command surfaced as `check-architecture`
