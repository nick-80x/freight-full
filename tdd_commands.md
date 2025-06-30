# TDD Custom Commands

## /tdd-cycle.md
```markdown
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
```

## /red.md
```markdown
# TDD Red Phase

Create a failing test for: $ARGUMENTS

Steps:
1. Identify the behavior to test
2. Write a test that describes the expected behavior
3. Use descriptive test names that explain the scenario
4. Include edge cases and error conditions
5. Run the test to confirm it fails
6. Commit with: "test: add failing test for $ARGUMENTS"

Follow Arrange-Act-Assert pattern:
- **Arrange**: Set up test data and mocks
- **Act**: Execute the function/method being tested  
- **Assert**: Verify the expected outcome
```

## /green.md
```markdown
# TDD Green Phase

Implement minimum code to make tests pass for: $ARGUMENTS

Guidelines:
1. Write only enough code to make the failing test pass
2. Don't add extra functionality not covered by tests
3. Use the simplest implementation that works
4. Run tests frequently to ensure they pass
5. Don't worry about code quality yet (that's for refactor phase)
6. Commit with: "feat: implement $ARGUMENTS to pass tests"

Focus on making tests green, not on perfect code.
```

## /refactor.md
```markdown
# TDD Refactor Phase

Improve the implementation for: $ARGUMENTS while keeping tests green

Refactoring opportunities:
1. Extract duplicated code into functions
2. Improve variable and function names
3. Simplify complex conditional logic
4. Optimize performance if needed
5. Add proper error handling
6. Improve code organization and structure

Rules:
- Run tests after each small change
- If tests break, revert and try smaller steps
- Commit frequently with: "refactor: improve $ARGUMENTS implementation"
- Don't change test behavior, only implementation
```

## /mock-api.md
```markdown
# Generate API Mocks

Create comprehensive API mocks for: $ARGUMENTS

Steps:
1. **Analyze API Requirements**
   - Identify endpoints needed
   - Determine request/response structures
   - Note authentication requirements

2. **Create MSW Handlers**
   - Set up REST/GraphQL handlers
   - Include realistic response data
   - Add error scenarios (400, 401, 404, 500)
   - Implement request validation

3. **Generate Mock Data**
   - Create realistic test data
   - Include edge cases and boundary values
   - Add data relationships and constraints
   - Consider pagination and filtering

4. **Setup Mock Server**
   - Configure MSW for test environment
   - Add request/response logging
   - Include network delay simulation
   - Set up different scenarios (success/error)

5. **Write Integration Tests**
   - Test API integration with mocks
   - Verify error handling
   - Test loading states
   - Validate data transformations
```

## /test-component.md
```markdown
# Generate Component Tests

Create comprehensive tests for React component: $ARGUMENTS

Test Categories:

## 1. Rendering Tests
- Component renders without crashing
- Renders with default props
- Renders with custom props
- Conditional rendering scenarios

## 2. Interaction Tests  
- Button clicks and form submissions
- Keyboard navigation
- Mouse events (hover, focus, blur)
- Touch events for mobile

## 3. Props Testing
- Required props validation
- Optional props with defaults
- Props type validation
- Invalid props handling

## 4. State Management
- Initial state is correct
- State updates on user interaction
- State persistence across re-renders
- Complex state scenarios

## 5. Integration Tests
- API calls and responses
- Context consumption
- Hook integrations
- Parent-child communication

## 6. Accessibility Tests
- ARIA attributes
- Keyboard navigation
- Screen reader compatibility
- Focus management

## 7. Error Boundary Tests
- Error handling scenarios
- Fallback UI rendering
- Error recovery mechanisms
```

## /coverage-analysis.md
```markdown
# Test Coverage Analysis

Analyze and improve test coverage for: $ARGUMENTS

Steps:

1. **Run Coverage Report**
   ```bash
   npm test -- --coverage --watchAll=false
   ```

2. **Identify Coverage Gaps**
   - Lines not covered
   - Branches not tested
   - Functions never called
   - Statements not executed

3. **Prioritize Missing Tests**
   - Critical business logic
   - Error handling paths
   - Edge cases and boundary conditions
   - Integration points

4. **Add Missing Tests**
   - Write tests for uncovered lines
   - Test all conditional branches
   - Cover error scenarios
   - Test async operations

5. **Verify Improvement**
   - Re-run coverage report
   - Ensure threshold is met (85%+)
   - Review coverage details
   - Update CI/CD if needed

Target: 85%+ coverage across all metrics (lines, branches, functions, statements)
```

## /api-integration-test.md
```markdown
# API Integration Testing

Create integration tests for API endpoints: $ARGUMENTS

Test Structure:

## 1. Setup and Teardown
- Database seeding
- Authentication setup
- Mock external services
- Clean test environment

## 2. Happy Path Tests
- Successful API calls
- Correct response format
- Data persistence verification
- Status code validation

## 3. Error Scenarios
- Invalid request data
- Authentication failures
- Authorization issues
- Network timeouts
- Server errors (500)

## 4. Edge Cases
- Boundary value testing
- Large payload handling
- Rate limiting
- Concurrent requests

## 5. Data Validation
- Input sanitization
- Output format consistency
- Database constraints
- Business rule validation

Use supertest for HTTP testing and MSW for external API mocking.
```