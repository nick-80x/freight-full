# GitHub MCP Server Configuration

## Overview
This configuration sets up the GitHub MCP server for the Freight project, enabling AI-assisted code management, repository operations, and development workflow automation.

## Features
- **Repository Management**: Create, clone, and manage repositories
- **Code Analysis**: Review code, analyze commits, and track changes
- **Issue Tracking**: Create, update, and manage GitHub issues
- **Pull Request Management**: Create PRs, review code, and manage merges
- **Branch Operations**: Create, switch, and merge branches
- **Release Management**: Tag releases and manage deployment workflows

## Setup Instructions

1. **Install the GitHub MCP Server**
   ```bash
   npm install -g @modelcontextprotocol/server-github
   ```

2. **GitHub Token Setup**
   Create a Personal Access Token with required permissions:

   **Required Scopes:**
   - `repo` (Full repository access)
   - `read:user` (Read user profile data)
   - `read:org` (Read organization data)
   - `workflow` (GitHub Actions workflow access)

   **Optional Scopes for Enhanced Features:**
   - `admin:repo_hook` (Repository webhook management)
   - `read:discussion` (GitHub Discussions access)
   - `read:packages` (GitHub Packages access)

3. **Environment Variables**
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
   export GITHUB_USERNAME="your_username"
   export GITHUB_ORG="your_organization"  # Optional
   ```

4. **Claude Desktop Integration**
   Add this configuration to your Claude Desktop settings:
   ```json
   {
     "mcpServers": {
       "github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
         }
       }
     }
   }
   ```

## Freight Project Integration

### Repository Structure
```
freight/
├── api/                    # FastAPI backend
├── worker/                 # Celery workers
├── frontend/              # Next.js frontend
├── infrastructure/        # Docker & deployment configs
├── docs/                  # Documentation
├── tests/                 # Test suites
├── scripts/               # Utility scripts
└── .github/
    ├── workflows/         # CI/CD pipelines
    ├── ISSUE_TEMPLATE/    # Issue templates
    └── PULL_REQUEST_TEMPLATE.md
```

### Workflow Automation
```yaml
# .github/workflows/ci.yml
name: Freight CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v4
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'

    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install -r requirements-dev.txt

    - name: Run tests
      run: |
        pytest tests/ -v --cov=freight

    - name: Run Celery tests
      run: |
        celery -A freight.worker.app worker --detach
        pytest tests/integration/ -v
```

## Usage Examples

### Repository Management
```
"Create a new branch called 'feature/migration-retry-enhancement' from main"
"Show me the latest commits on the develop branch"
"Create a pull request from feature/api-improvements to main"
"Merge the pull request #45 after CI passes"
```

### Code Analysis
```
"Analyze the changes in the last 5 commits to the API module"
"Show me all files modified in pull request #32"
"Find all Python files that import the 'celery' module"
"Review the code changes in src/freight/migration/retry.py"
```

### Issue Management
```
"Create an issue for implementing exponential backoff in retry logic"
"List all open bugs labeled with 'high-priority'"
"Assign issue #78 to the migration team"
"Close issue #65 and reference it in commit message"
```

### Release Management
```
"Create a new release tag v1.2.0 with changelog"
"Show me all releases from the last 6 months"
"Generate release notes for version 1.2.0"
"Deploy the latest release to staging environment"
```

### Development Workflow
```
"Show me all open pull requests that need review"
"Check the CI status for pull request #89"
"Find pull requests that modify the database schema"
"List all commits by author in the last sprint"
```

## Project-Specific Commands

### Freight Development
```
"Show me recent changes to the migration worker code"
"Find all issues related to PostgreSQL performance"
"Create a branch for implementing Redis clustering"
"Review the Docker configuration changes in the last week"
```

### Testing & Quality Assurance
```
"Check test coverage for the retry module"
"Find all failing tests in the latest CI run"
"Show me pull requests that don't have sufficient test coverage"
"List all open issues tagged with 'testing'"
```

### Documentation
```
"Update the README with new installation instructions"
"Create documentation for the new retry API endpoints"
"Find all TODO comments in the codebase"
"Generate API documentation from code comments"
```

## Integration with Other MCP Servers

### Database Operations
Combine GitHub MCP with PostgreSQL MCP:
```
"Show me the database migration files changed in PR #45 and analyze their impact"
"Create a GitHub issue for the database performance problems we found in PostgreSQL"
```

### Infrastructure Management
Combine with Docker MCP:
```
"Show me the Docker configuration changes in the latest commits"
"Create a PR to update the container deployment strategy"
```

### API Development
Combine with FastAPI MCP:
```
"Review the API endpoint changes in the current branch"
"Create tests for the new migration endpoints added in PR #67"
```

## Security Best Practices

### Token Security
- Use environment variables for tokens
- Rotate tokens regularly
- Use minimal required scopes
- Monitor token usage in GitHub settings

### Repository Security
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    target-branch: "develop"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Branch Protection
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci/tests", "ci/security-scan"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true
  },
  "restrictions": null
}
```

## Advanced Features

### GitHub Actions Integration
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production
on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to Railway
      uses: railway-deploy-action@v1
      with:
        service: freight-api
        environment: production
```

### Code Quality Automation
```yaml
# .github/workflows/quality.yml
name: Code Quality
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run Black
      run: black --check .
    - name: Run isort
      run: isort --check-only .
    - name: Run flake8
      run: flake8 .
    - name: Run mypy
      run: mypy freight/
```

### Performance Monitoring
```yaml
# .github/workflows/performance.yml
name: Performance Tests
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
    - name: Run load tests
      run: |
        locust -f tests/performance/locustfile.py \
               --headless \
               --users 100 \
               --spawn-rate 10 \
               --run-time 300s \
               --host http://staging.freight.com
```

This GitHub MCP server integration provides comprehensive repository management and development workflow automation for the Freight project, enabling AI-assisted code review, issue tracking, and continuous integration operations.
