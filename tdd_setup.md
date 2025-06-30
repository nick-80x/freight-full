# Claude Code TDD Setup Guide

Complete setup guide for implementing Test-Driven Development with automated commits, builds, tests, and API mocking using Claude Code.

## Table of Contents
1. [Configuration Setup](#configuration-setup)
2. [Custom TDD Commands](#custom-tdd-commands)
3. [Dependencies Installation](#dependencies-installation)
4. [Project Configuration](#project-configuration)
5. [Implementation Steps](#implementation-steps)
6. [Testing Your Setup](#testing-your-setup)
7. [Usage Examples](#usage-examples)

---

## Configuration Setup

### Step 1: Create Claude Code Configuration

Navigate to your project directory and create the configuration:

```bash
cd your-project
mkdir -p .claude
```

Create `.claude/settings.local.json` with the following content:

```json
{
  "workflows": {
    "git": {
      "autoCommit": true,
      "autoStage": true,
      "commitMessageTemplate": "{type}: {description}",
      "useConventionalCommits": true,
      "autoGenerateCommitMessages": true,
      "signCommits": false,
      "pushAfterCommit": false,
      "requireCommitConfirmation": false,
      "includeCo-author": false,
      "maxCommitMessageLength": 72,
      "enforceCommitMessageFormat": true,
      "preferredCommitTypes": ["test", "feat", "fix", "refactor", "docs"],
      "tddCommitPattern": {
        "redPhase": "test: add failing test for {feature}",
        "greenPhase": "feat: implement {feature} to pass tests",
        "refactorPhase": "refactor: improve {feature} implementation"
      }
    },
    
    "tdd": {
      "enabled": true,
      "enforceTestFirst": true,
      "testFileNaming": "{component}.test.{ext}",
      "testDirectory": "__tests__",
      "mockDirectory": "__mocks__",
      "followRedGreenRefactor": true,
      "autoRunTestsOnSave": true,
      "coverageThreshold": 85,
      "requireTestsForNewFeatures": true,
      "testFrameworks": {
        "unit": "jest",
        "integration": "jest",
        "e2e": "cypress"
      },
      "testPatterns": {
        "unit": "**/*.test.{js,ts,jsx,tsx}",
        "integration": "**/*.integration.test.{js,ts}",
        "component": "**/*.component.test.{js,ts,jsx,tsx}"
      }
    },

    "testing": {
      "autoRunTests": true,
      "testOnSave": true,
      "testOnCommit": true,
      "watchMode": true,
      "parallelTests": true,
      "testTimeout": 10000,
      "retryFailedTests": 2,
      "generateCoverageReport": true,
      "coverageFormats": ["html", "lcov", "text"],
      "failOnCoverageThreshold": true,
      "testEnvironment": "jsdom",
      "setupFilesAfterEnv": ["<rootDir>/src/setupTests.js"],
      "collectCoverageFrom": [
        "src/**/*.{js,jsx,ts,tsx}",
        "!src/**/*.test.{js,jsx,ts,tsx}",
        "!src/index.js",
        "!src/setupTests.js"
      ]
    },

    "build": {
      "autoBuild": true,
      "buildOnCommit": true,
      "buildOnTest": true,
      "optimizeBuilds": true,
      "enableCaching": true,
      "buildTarget": "development",
      "bundleAnalysis": false,
      "typeCheck": true,
      "lint": true,
      "formatCheck": true,
      "buildSteps": [
        "lint",
        "type-check", 
        "test",
        "build"
      ],
      "failOnWarnings": false,
      "cleanBeforeBuild": true
    },

    "apiMocking": {
      "enabled": true,
      "mockingLibrary": "msw",
      "mockServerPort": 3001,
      "autoStartMockServer": true,
      "mockDataDirectory": "src/__mocks__/data",
      "mockHandlersDirectory": "src/__mocks__/handlers",
      "generateMockData": true,
      "mockStrategies": {
        "rest": "msw",
        "graphql": "msw",
        "websocket": "mock-socket"
      },
      "mockingPatterns": {
        "interceptAllRequests": false,
        "onlyTestEnvironment": true,
        "mockExternalAPIs": true,
        "preserveNetworkLogs": true
      },
      "defaultMockResponses": {
        "delay": 100,
        "successRate": 0.95,
        "includeHeaders": true,
        "enableCORS": true
      }
    },

    "development": {
      "autoInstallDependencies": true,
      "preferredPackageManager": "npm",
      "autoStartDevServer": false,
      "hotReload": true,
      "verboseLogging": true,
      "enableSourceMaps": true,
      "debugMode": false,
      "environmentVariables": {
        "NODE_ENV": "development",
        "REACT_APP_API_URL": "http://localhost:3001",
        "REACT_APP_MOCK_API": "true"
      }
    },

    "codeGeneration": {
      "generateTestFiles": true,
      "generateMockFiles": true,
      "testTemplates": {
        "component": "react-component-test.template",
        "hook": "react-hook-test.template", 
        "utility": "utility-function-test.template",
        "service": "api-service-test.template"
      },
      "mockTemplates": {
        "apiHandler": "msw-handler.template",
        "mockData": "mock-data.template",
        "mockComponent": "mock-component.template"
      },
      "autoImportTestUtilities": true,
      "includeSetupTeardown": true
    },

    "qualityChecks": {
      "enablePrettier": true,
      "enableESLint": true,
      "enableTypeScript": true,
      "autoFixLinting": true,
      "strictTypeChecking": true,
      "requireTestDocumentation": true,
      "enforceNamingConventions": true,
      "testFileRequirements": {
        "mustHaveDescribe": true,
        "mustHaveBeforeEach": false,
        "mustHaveAfterEach": false,
        "minimumAssertions": 1
      }
    },

    "customCommands": {
      "enableSlashCommands": true,
      "commandsPath": ".claude/commands",
      "tddCommands": {
        "/red": "Create failing test for the specified feature",
        "/green": "Implement minimum code to make tests pass", 
        "/refactor": "Improve code while keeping tests green",
        "/mock-api": "Generate API mocks for the specified endpoint",
        "/test-component": "Generate comprehensive component tests",
        "/tdd-cycle": "Run complete TDD cycle for feature: red -> green -> refactor"
      },
      "quickActions": {
        "runTests": "npm test",
        "runTestsWatch": "npm test -- --watch",
        "runCoverage": "npm test -- --coverage",
        "buildProject": "npm run build",
        "lintFix": "npm run lint -- --fix",
        "typeCheck": "npm run type-check"
      }
    },

    "notifications": {
      "testResults": true,
      "buildStatus": true,
      "coverageReports": true,
      "commitStatus": true,
      "soundEnabled": false,
      "desktopNotifications": true,
      "slackIntegration": false
    },

    "aiBehavior": {
      "tddFocused": true,
      "explainTestStrategy": true,
      "suggestEdgeCases": true,
      "generateTestData": true,
      "mockingGuidance": true,
      "refactoringAdvice": true,
      "testCoverageAnalysis": true,
      "autoGenerateAssertions": true,
      "preferDescriptiveTestNames": true,
      "enforceArrangeActAssert": true
    }
  },

  "tools": {
    "allowedTools": [
      "Edit",
      "View", 
      "Create",
      "Delete",
      "Bash(npm test*)",
      "Bash(npm run*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git status)",
      "Bash(jest*)",
      "Bash(npx*)"
    ],
    "testingTools": [
      "jest",
      "react-testing-library",
      "msw",
      "cypress",
      "supertest"
    ]
  },

  "env": {
    "NODE_ENV": "test",
    "CI": "false",
    "MOCK_API": "true",
    "TEST_TIMEOUT": "10000",
    "COVERAGE_THRESHOLD": "85"
  }
}
```

---

## Custom TDD Commands

Create the commands directory and individual command files:

```bash
mkdir -p .claude/commands
```

### .claude/commands/tdd-cycle.md
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

### .claude/commands/red.md
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

### .claude/commands/green.md
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

### .claude/commands/refactor.md
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

### .claude/commands/mock-api.md
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

### .claude/commands/test-component.md
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

### .claude/commands/coverage-analysis.md
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

### .claude/commands/api-integration-test.md
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

---

## Dependencies Installation

Install all required dependencies for the TDD workflow:

```bash
# Core testing dependencies
npm install --save-dev jest @testing-library/react @testing-library/jest-dom @testing-library/user-event

# MSW for API mocking
npm install --save-dev msw

# Additional testing utilities
npm install --save-dev supertest

# E2E testing (optional)
npm install --save-dev cypress

# Code quality tools
npm install --save-dev eslint prettier typescript

# TypeScript support for Jest (if using TypeScript)
npm install --save-dev ts-jest @types/jest

# Additional MSW setup for Node environments
npm install --save-dev whatwg-fetch
```

### Initialize MSW
```bash
# Initialize MSW for browser mocking
npx msw init public/ --save

# Create mock directories
mkdir -p src/__mocks__/handlers
mkdir -p src/__mocks__/data
```

---

## Project Configuration

### Setup Test Configuration Files

#### src/setupTests.js
```javascript
import '@testing-library/jest-dom';
import { server } from './__mocks__/server';

// Establish API mocking before all tests
beforeAll(() => server.listen());

// Reset any request handlers that we may add during the tests,
// so they don't affect other tests
afterEach(() => server.resetHandlers());

// Clean up after the tests are finished
afterAll(() => server.close());
```

#### src/__mocks__/server.js
```javascript
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

// Setup requests interception with the given handlers
export const server = setupServer(...handlers);
```

#### src/__mocks__/handlers/index.js
```javascript
import { rest } from 'msw';

export const handlers = [
  // Example handler
  rest.get('/api/users', (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json([
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
      ])
    );
  }),
  
  rest.post('/api/users', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({ id: 3, name: 'New User', email: 'new@example.com' })
    );
  }),
];
```

#### Update package.json
Add these scripts to your package.json:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage --watchAll=false",
    "test:ci": "jest --coverage --watchAll=false --passWithNoTests",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "format": "prettier --write src/",
    "type-check": "tsc --noEmit",
    "build": "react-scripts build"
  },
  "jest": {
    "testEnvironment": "jsdom",
    "setupFilesAfterEnv": ["<rootDir>/src/setupTests.js"],
    "collectCoverageFrom": [
      "src/**/*.{js,jsx,ts,tsx}",
      "!src/**/*.test.{js,jsx,ts,tsx}",
      "!src/index.js",
      "!src/setupTests.js",
      "!src/reportWebVitals.js"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 85,
        "functions": 85,
        "lines": 85,
        "statements": 85
      }
    }
  }
}
```

#### Create CLAUDE.md (Project Guidelines)
```markdown
# Project Guidelines

This project follows Test-Driven Development (TDD) methodology.

## TDD Workflow
1. **Red Phase**: Write failing tests first
2. **Green Phase**: Implement minimum code to pass tests
3. **Refactor Phase**: Improve code while keeping tests green

## Testing Standards
- 85%+ code coverage required
- Use MSW for API mocking
- Follow Arrange-Act-Assert pattern
- Descriptive test names explaining the scenario
- Test files should be co-located with components

## Commit Message Format
Use conventional commits with TDD-specific patterns:
- `test: add failing test for {feature}` (Red phase)
- `feat: implement {feature} to pass tests` (Green phase)  
- `refactor: improve {feature} implementation` (Refactor phase)

## Code Quality
- ESLint and Prettier configured
- TypeScript strict mode enabled
- All functions should be pure when possible
- Prefer composition over inheritance

## API Integration
- Use MSW for mocking external APIs
- Create realistic mock data
- Test both success and error scenarios
- Include loading states in component tests

## File Structure
```
src/
├── components/
│   ├── ComponentName/
│   │   ├── ComponentName.jsx
│   │   ├── ComponentName.test.jsx
│   │   └── index.js
├── hooks/
├── services/
├── utils/
└── __mocks__/
    ├── handlers/
    ├── data/
    └── server.js
```

## Available Custom Commands
- `/tdd-cycle {feature}` - Complete TDD workflow
- `/red {feature}` - Create failing test
- `/green {feature}` - Implement feature
- `/refactor {feature}` - Improve implementation
- `/mock-api {endpoint}` - Generate API mocks
- `/test-component {component}` - Generate component tests
- `/coverage-analysis` - Analyze test coverage
```

---

## Implementation Steps

### Step 1: Initialize Your Project Structure
```bash
# Create necessary directories
mkdir -p src/components
mkdir -p src/hooks
mkdir -p src/services
mkdir -p src/utils
mkdir -p src/__mocks__/handlers
mkdir -p src/__mocks__/data

# Create git repository if not already done
git init
git add .
git commit -m "chore: initial project setup with TDD configuration"
```

### Step 2: Start Claude Code
```bash
# Navigate to your project directory
cd your-project

# Launch Claude Code
claude
```

### Step 3: Verify Configuration
In Claude Code, run:
```
/help
```
You should see your custom TDD commands listed.

### Step 4: Test the Setup
```
"Let's test our TDD setup by creating a simple Button component"
```

Claude should now follow the TDD workflow automatically.

---

## Testing Your Setup

### Verify Custom Commands Work
```bash
# In Claude Code:
/red "user authentication button"
/green "user authentication button"
/refactor "user authentication button"
/mock-api "auth endpoints"
/test-component "Button"
/coverage-analysis
```

### Test Automated Workflows
1. **Create a simple component using TDD**:
   ```
   "Create a Counter component using TDD that increments and decrements a number"
   ```

2. **Verify git automation**:
   Check that commits are created automatically with proper messages.

3. **Test API mocking**:
   ```
   "Create a UserService that fetches user data with proper mocking"
   ```

4. **Check coverage reporting**:
   ```bash
   npm run test:coverage
   ```

---

## Usage Examples

### Example 1: Creating a Login Component
```
/tdd-cycle "login form component with email and password validation"
```

Expected behavior:
1. Creates failing tests for form validation
2. Implements basic form structure
3. Adds validation logic
4. Refactors for better code quality
5. Generates appropriate commit messages at each phase

### Example 2: API Integration
```
/mock-api "user authentication endpoints"
```

Then:
```
"Create a useAuth hook that handles login, logout, and token refresh"
```

### Example 3: Component Testing
```
/test-component "ProductCard component that displays product information with buy button"
```

### Example 4: Coverage Analysis
```
/coverage-analysis "authentication module"
```

---

## Troubleshooting

### Common Issues

1. **Commands not appearing**: 
   - Ensure `.claude/commands/` directory exists
   - Check file extensions are `.md`
   - Restart Claude Code

2. **Tests not running automatically**:
   - Verify Jest is installed
   - Check `package.json` scripts
   - Ensure `setupTests.js` exists

3. **MSW not working**:
   - Run `npx msw init public/ --save`
   - Check server setup in `__mocks__/server.js`
   - Verify handlers are exported correctly

4. **Git automation not working**:
   - Check Claude Code has git permissions
   - Verify repository is initialized
   - Ensure working directory is clean

### Debug Mode
Enable verbose logging by adding to your settings:
```json
{
  "development": {
    "verboseLogging": true,
    "debugMode": true
  }
}
```

---

## Next Steps

1. **Start with a simple feature**: Try creating a basic component using `/tdd-cycle`
2. **Explore API mocking**: Use `/mock-api` to set up service mocking
3. **Analyze coverage**: Regular use of `/coverage-analysis` to maintain quality
4. **Customize further**: Adjust settings based on your project needs
5. **Team integration**: Share the setup with your team via git

## Additional Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code/)
- [MSW Documentation](https://mswjs.io/)
- [Jest Testing Framework](https://jestjs.io/)
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)

---

**Happy TDD coding with Claude Code! 🚀**