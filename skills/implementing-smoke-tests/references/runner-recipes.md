# Runner Recipes

Use this file only after the runner has been selected.

## Playwright smoke

Use when:

- the repository already uses Playwright for browser automation
- or the repository is a JS or TS web app with no browser automation and needs a default runner

Implement with:

- smoke-tagged tests such as `@smoke` or a dedicated smoke project
- stable locators based on role, label, or explicit test ids
- programmatic auth via storage state, setup project, or direct API login when available
- one smoke command exposed through the existing package manager

Typical command shape:

```bash
pnpm playwright test --grep @smoke
```

or:

```bash
pnpm playwright test --project=smoke
```

## Cypress smoke

Use when:

- the repository already uses Cypress for browser tests

Implement with:

- a dedicated smoke spec folder or a clear smoke naming pattern
- custom commands or API shortcuts for login and seed setup instead of long UI setup flows
- user-visible assertions with stable selectors
- a smoke-only script based on `cypress run --spec`

Typical command shape:

```bash
npm run cypress -- --spec "cypress/e2e/smoke/**/*.cy.ts"
```

## pytest smoke

Use when:

- the repository is a Python API or service and already uses `pytest`

Implement with:

- a registered `smoke` marker in the repo's pytest config
- a small set of endpoint or service-level tests tagged with `@pytest.mark.smoke`
- fixtures that seed required state before each test or per test session as needed
- direct assertions on status codes, payload shape, and one critical state change

Typical command shape:

```bash
pytest -m smoke
```

## Vitest smoke

Use when:

- the repository is a Node service and already uses `vitest`

Implement with:

- a smoke file naming convention such as `*.smoke.test.ts`
- or a smoke naming pattern supported by the repository's current scripts
- direct setup helpers for auth, seeded data, and HTTP clients
- assertions on baseline read and write paths with minimal fixture overhead

Typical command shape:

```bash
vitest run "src/**/*.smoke.test.ts"
```

## Jest smoke

Use when:

- the repository is a Node service and already uses `jest`

Implement with:

- a smoke file naming convention or a `testNamePattern` strategy
- existing setup files and test helpers rather than new parallel harnesses
- minimal end-to-end service assertions for health, auth, and one write path

Typical command shape:

```bash
jest --runInBand --testPathPatterns smoke
```

## XCTest and XCUITest smoke

Use when:

- the repository is an iOS app and already uses `XCTest` or `XCUITest`
- or the repository has iOS test targets but no smoke-only selection yet

Implement with:

- a small `XCUITest` smoke set for cold launch, login or anonymous entry, and one baseline read or write flow
- accessibility identifiers and stable visible text rather than brittle coordinate taps
- launch arguments, seeded fixtures, or mocked endpoints to avoid long UI setup
- a dedicated test plan, scheme, or targeted `xcodebuild test` invocation for smoke runs

Typical command shape:

```bash
xcodebuild test -scheme AppUITests -only-testing:AppUITests/SmokeTests
```

## Android Espresso smoke

Use when:

- the repository is an Android app and already uses Espresso or standard instrumented UI tests

Implement with:

- a narrow instrumented smoke suite for launch, auth, one core read, and one state change
- stable view matchers, content descriptions, and test tags instead of brittle timing-based selectors
- mock servers, fake repositories, or seeded backend state to keep setup short
- a dedicated Gradle task, package, or class filter for smoke execution

Typical command shape:

```bash
./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.SmokeSuite
```

## Android UI Automator smoke

Use when:

- the Android smoke flow must cross app boundaries
- or the suite must handle system UI such as permission dialogs or settings handoffs

Implement with:

- only the boundary steps that Espresso cannot cover cleanly
- explicit app-state setup so tests do not depend on previous runs
- stable selectors for system UI and permission surfaces
- a dedicated instrumentation selection path separate from the broader Android suite

Typical command shape:

```bash
./gradlew connectedDebugAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.uiautomator.SmokeSuite
```

## Flutter integration_test smoke

Use when:

- the repository is a Flutter app and uses or can add `integration_test`

Implement with:

- smoke tests under `integration_test/` using a clear smoke naming pattern
- keys, semantics labels, or stable visible text for locator strategy
- seeded state, fake backends, or startup overrides to keep flows deterministic
- one dedicated Flutter test command for smoke in CI

Typical command shape:

```bash
flutter test integration_test/smoke_test.dart
```

## Common implementation rules

Apply these rules regardless of runner:

- keep smoke to roughly three through seven baseline flows
- make tests order-independent
- prefer setup and fixture reset before tests, not teardown cleanup after failures
- isolate third-party dependencies behind mocks, stubs, or contract boundaries when they are not the system under test
- prefer a single primary simulator, emulator, or device target for smoke unless the repo already requires more
- emit one machine-readable report format and expose its path in CI output where the runner supports it
- include repro commands and artifact paths in the failure summary instead of relying on raw logs alone
- keep default stdout terse and structured; push verbose framework logs into artifacts or secondary CI sections
- keep diagnostics light and preserve heavy artifacts only on failure
