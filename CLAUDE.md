# 🤖 Claude Standard Workflow
---

## 🧠 Step 1: Think Before You Code
- Carefully read and understand the problem or feature request.
- Scan the existing codebase for relevant files and logic.
- Write a clear plan in `todo.md` before making any changes.

---

## 📝 Step 2: Plan the Work in `todo.md`
- Create a checklist of small, clear TODO items.
- Each item should be simple and minimally impactful.
- Avoid bundling complex or sweeping changes into one task.

---

## ✅ Step 3: Wait for Approval
- Do **not** begin work until I review and approve the plan in `todo.md`.

---

## 🛠 Step 4: Execute the Plan
- Complete TODOs one by one.
- Mark each item as complete as you go (`[x]`).
- Keep changes minimal and focused — no large refactors.

---

## 📣 Step 5: Communicate Progress
- After each completed task, give me a short, high-level explanation:
  - What changed
  - Why it changed
  - What impact it has

---

## 🔒 Step 6: Emphasize Simplicity
- Prioritize clarity and maintainability over cleverness.
- Minimize the surface area of each change.
- Don’t optimize prematurely.

---

## 📋 Step 7: Review Summary
- When done, add a `## Review` section to `todo.md` that includes:
  - Summary of changes made
  - Any follow-up questions or considerations
  - Anything I need to review, test, or deploy

---

By following this workflow, we'll stay fast, clean, and collaborative. Thank you!

---

# 🧪 TDD Project Guidelines

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

---

# 🔌 MCP Servers Integration

This project includes comprehensive MCP (Model Context Protocol) server configurations that enable AI-assisted development workflows.

## Configured MCP Servers

### 🗄️ **PostgreSQL MCP Server**
- **Purpose**: Database inspection and natural language queries
- **Features**: Schema analysis, migration monitoring, multi-tenant data access
- **Usage**: "Show me all failed migration jobs from the last 24 hours"

### 🔴 **Redis MCP Server**
- **Purpose**: Celery queue monitoring and Redis operations
- **Features**: Task queue inspection, job status tracking, performance monitoring
- **Usage**: "Check the current Celery queue length and failed tasks"

### ⚡ **FastAPI MCP Integration**
- **Purpose**: Freight API endpoint exposure
- **Features**: Job management, retry operations, real-time monitoring
- **Usage**: "Create a migration job for tenant 'acme-corp' with batch size 500"

### 🐳 **Docker MCP Server**
- **Purpose**: Container and infrastructure management
- **Features**: Container lifecycle, compose operations, resource monitoring
- **Usage**: "Start the Freight development environment and check container health"

### 🐙 **GitHub MCP Server**
- **Purpose**: Repository and development workflow management
- **Features**: Code analysis, PR management, issue tracking, CI/CD monitoring
- **Usage**: "Create a new branch for the retry enhancement feature"

## Setup Instructions

1. **Install MCP Servers**
   ```bash
   cd mcp-servers
   ./install-mcp-servers.sh
   ```

2. **Configure Environment Variables**
   ```bash
   export DATABASE_URL="postgresql://user:pass@localhost:5432/freight"
   export REDIS_URL="redis://localhost:6379"
   export GITHUB_PERSONAL_ACCESS_TOKEN="your_token_here"
   ```

3. **Test Configuration**
   ```bash
   ./test-mcp-setup.sh
   ```

4. **Integrate with Claude Desktop**
   Copy `mcp-servers/claude-desktop-config.json` to your Claude Desktop configuration.

## Benefits

- **Natural Language Interface**: Query databases, manage containers, and control APIs using plain English
- **Integrated Workflow**: Seamlessly switch between development, testing, and operations tasks
- **Multi-Service Coordination**: Combine insights from database, queue, API, and repository data
- **AI-Powered Automation**: Automate complex development workflows with intelligent assistance

See `mcp-servers/README.md` for detailed configuration and usage instructions.