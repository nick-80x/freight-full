# TDD Complete Cycle

Execute a complete Test-Driven Development cycle for: $ARGUMENTS

Follow these steps:

## Red Phase
1. Write a failing test that describes the desired behavior
2. Run tests to confirm the new test fails
3. Commit with message: "test: add failing test for $ARGUMENTS"

## Green Phase  
1. Write the minimum code needed to make the test pass
2. Run tests to confirm they all pass
3. Commit with message: "feat: implement $ARGUMENTS to pass tests"

## Refactor Phase
1. Improve the code while keeping all tests green
2. Run tests after each refactoring step
3. Commit with message: "refactor: improve $ARGUMENTS implementation"

## Final Steps
- Run full test suite with coverage
- Ensure coverage meets threshold (85%+)
- Run build to verify no breaking changes