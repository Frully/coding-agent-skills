# Stack Selection

Use this file after the initial repository inventory when the runner choice is not obvious.

## Selection priorities

Apply these rules in order:

1. Reuse the repository's existing test runner for the same test layer whenever that runner can support a smoke-only lane.
2. Avoid adding a second browser automation framework to a repository that already has one.
3. Avoid adding a second API test runner to a repository that already has one with filtering support.
4. For native mobile, prefer the platform's standard UI test stack before introducing a cross-app automation layer.
5. Prefer the smallest change that produces a stable, fast smoke command and CI path.

## Runner matrix

### Browser applications

If browser automation already exists:

- Playwright present: extend Playwright with tags or a dedicated smoke project.
- Cypress present: extend Cypress with a dedicated smoke spec path or `--spec` script.

If browser automation does not exist:

- JS or TS web app: default to Playwright.
- Non-JS web app with an established browser runner already vendored in the repo: reuse that runner.
- Non-JS web app with no browser runner and no obvious package workflow: stop and return a repo-specific implementation plan instead of imposing a new toolchain.

### Python APIs

- `pytest` present: reuse it and filter with a registered `smoke` marker.
- another Python test runner present without a clear smoke filter path: prefer a concrete plan unless the repository already has an obvious equivalent pattern.

### Node APIs

- `vitest` present: reuse it with smoke file naming or test-name filtering.
- `jest` present: reuse it with smoke file naming or `--testNamePattern` and related path filtering.
- another Node runner present with established selection patterns: reuse if the repo already documents that approach.
- no existing runner: do not add Postman, Newman, or a second framework by default; return a concrete plan based on the current codebase and scripts.

### iOS applications

- existing `XCTest` plus `XCUITest` target: reuse it and create a smoke-only plan through a dedicated scheme, plan, or focused test selection.
- unit tests only and no UI target yet: prefer adding an `XCUITest` target over introducing a third-party harness.
- mixed Swift Testing and XCTest repo: keep UI smoke in `XCTest` or `XCUITest`, because that remains the standard path for UI tests.

### Android applications

- Espresso present: reuse it for in-app smoke flows.
- flows cross app boundaries, system settings, or permission dialogs: use UI Automator where Espresso is too app-local.
- both Espresso and UI Automator present: keep in-app flows in Espresso and reserve UI Automator for boundary cases.
- no instrumentation UI tests yet: prefer the repository's standard Android test stack before considering external frameworks.

### Flutter applications

- `integration_test` present: reuse it for smoke flows.
- widget tests only and no device-level tests yet: prefer adding `integration_test` before inventing a parallel harness.
- mixed Flutter plus native wrappers: keep smoke in `integration_test` unless the critical flow truly lives in native-only UI.

## Reuse policy

When reusing an existing runner:

- keep the repository's current config style and file placement unless it blocks a clean smoke lane
- follow the current package manager and command naming conventions
- reuse existing fixtures, custom commands, auth helpers, and seeded data utilities before inventing new ones
- reuse existing simulator, emulator, scheme, or device boot helpers before adding new orchestration
- preserve the full suite behavior; smoke should be additive, not a rewrite of the existing suite

## Fallback policy

Return a plan instead of forcing implementation when any of these are true:

- the stack is outside the supported web, HTTP API, iOS, Android, or Flutter scope
- no stable non-interactive setup path exists for authentication or data seeding
- the repository has no reliable way to boot the app or API in CI yet
- the mobile app requires hardware, OS permissions, or external dependencies that cannot be stabilized in the current CI path
- adding a new tool would introduce a larger operational burden than the smoke lane justifies

When you fall back to a plan, still return:

- the recommended runner and why
- the proposed smoke flows
- the intended smoke command
- the CI path that should eventually run it
