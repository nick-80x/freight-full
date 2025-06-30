#!/bin/bash

# Freight MCP Servers Test Script
# This script validates the MCP server setup and configuration

set -e

echo "🧪 Freight MCP Servers Test Suite"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass_test() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

warn_test() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

# Test 1: Check Node.js installation
echo -e "\n📦 Testing Node.js and npm..."
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    pass_test "Node.js $NODE_VERSION and npm $NPM_VERSION are installed"
else
    fail_test "Node.js or npm not found. Required for MCP servers."
fi

# Test 2: Check Python installation
echo -e "\n🐍 Testing Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    pass_test "Python3 is installed: $PYTHON_VERSION"
else
    fail_test "Python3 not found. Required for FastAPI MCP integration."
fi

# Test 3: Check pip installation
if command -v pip3 &> /dev/null; then
    PIP_VERSION=$(pip3 --version)
    pass_test "pip3 is installed: $PIP_VERSION"
else
    fail_test "pip3 not found. Required for Python dependencies."
fi

# Test 4: Check Docker installation
echo -e "\n🐳 Testing Docker installation..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    pass_test "Docker is installed: $DOCKER_VERSION"
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        pass_test "Docker daemon is running"
    else
        fail_test "Docker daemon is not running"
    fi
else
    fail_test "Docker not found. Required for container management."
fi

# Test 5: Check MCP Server Installations
echo -e "\n🔧 Testing MCP server installations..."

# PostgreSQL MCP Server
if npm list -g @modelcontextprotocol/server-postgres &> /dev/null; then
    pass_test "PostgreSQL MCP server is installed"
else
    warn_test "PostgreSQL MCP server not installed. Run: npm install -g @modelcontextprotocol/server-postgres"
fi

# Redis MCP Server
if npm list -g @redis/mcp-redis &> /dev/null; then
    pass_test "Redis MCP server is installed"
else
    warn_test "Redis MCP server not installed. Run: npm install -g @redis/mcp-redis"
fi

# Docker MCP Server
if npm list -g @modelcontextprotocol/server-docker &> /dev/null; then
    pass_test "Docker MCP server is installed"
else
    warn_test "Docker MCP server not installed. Run: npm install -g @modelcontextprotocol/server-docker"
fi

# GitHub MCP Server
if npm list -g @modelcontextprotocol/server-github &> /dev/null; then
    pass_test "GitHub MCP server is installed"
else
    warn_test "GitHub MCP server not installed. Run: npm install -g @modelcontextprotocol/server-github"
fi

# Test 6: Check Environment Variables
echo -e "\n🔐 Testing environment variables..."

if [[ -n "$DATABASE_URL" ]]; then
    pass_test "DATABASE_URL is set"
else
    warn_test "DATABASE_URL not set. Required for PostgreSQL MCP server."
fi

if [[ -n "$REDIS_URL" ]]; then
    pass_test "REDIS_URL is set"
else
    warn_test "REDIS_URL not set. Required for Redis MCP server."
fi

if [[ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
    pass_test "GITHUB_PERSONAL_ACCESS_TOKEN is set"
else
    warn_test "GITHUB_PERSONAL_ACCESS_TOKEN not set. Required for GitHub MCP server."
fi

if [[ -n "$DOCKER_HOST" ]]; then
    pass_test "DOCKER_HOST is set"
else
    warn_test "DOCKER_HOST not set. Using default Docker socket."
fi

# Test 7: Check Service Connectivity
echo -e "\n🌐 Testing service connectivity..."

# Test PostgreSQL connectivity
if [[ -n "$DATABASE_URL" ]]; then
    if command -v psql &> /dev/null; then
        if psql "$DATABASE_URL" -c "SELECT 1;" &> /dev/null; then
            pass_test "PostgreSQL database is accessible"
        else
            fail_test "Cannot connect to PostgreSQL database"
        fi
    else
        warn_test "psql not found. Cannot test PostgreSQL connectivity."
    fi
fi

# Test Redis connectivity
if [[ -n "$REDIS_URL" ]]; then
    if command -v redis-cli &> /dev/null; then
        if redis-cli -u "$REDIS_URL" ping &> /dev/null; then
            pass_test "Redis server is accessible"
        else
            fail_test "Cannot connect to Redis server"
        fi
    else
        warn_test "redis-cli not found. Cannot test Redis connectivity."
    fi
fi

# Test GitHub API connectivity
if [[ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
    if command -v curl &> /dev/null; then
        if curl -s -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
                https://api.github.com/user &> /dev/null; then
            pass_test "GitHub API is accessible with provided token"
        else
            fail_test "Cannot access GitHub API with provided token"
        fi
    else
        warn_test "curl not found. Cannot test GitHub API connectivity."
    fi
fi

# Test 8: Check Configuration Files
echo -e "\n📋 Testing configuration files..."

if [[ -f "claude-desktop-config.json" ]]; then
    pass_test "Claude Desktop configuration file exists"
    
    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if jq empty claude-desktop-config.json &> /dev/null; then
            pass_test "Claude Desktop configuration is valid JSON"
        else
            fail_test "Claude Desktop configuration has invalid JSON syntax"
        fi
    else
        warn_test "jq not found. Cannot validate JSON syntax."
    fi
else
    fail_test "Claude Desktop configuration file not found"
fi

# Check individual MCP server configs
for dir in postgresql redis docker github fastapi-integration; do
    if [[ -d "$dir" ]]; then
        pass_test "MCP server directory exists: $dir"
        
        if [[ -f "$dir/README.md" ]]; then
            pass_test "Documentation exists for $dir"
        else
            warn_test "No README.md found for $dir"
        fi
    else
        fail_test "MCP server directory missing: $dir"
    fi
done

# Test 9: Check FastAPI Dependencies
echo -e "\n⚡ Testing FastAPI MCP integration..."

if [[ -f "fastapi-integration/requirements.txt" ]]; then
    pass_test "FastAPI requirements.txt exists"
    
    # Check if dependencies are installed
    if pip3 show fastapi &> /dev/null; then
        pass_test "FastAPI is installed"
    else
        warn_test "FastAPI not installed. Run: pip install fastapi"
    fi
    
    if pip3 show fastapi-mcp &> /dev/null; then
        pass_test "FastAPI-MCP is installed"
    else
        warn_test "FastAPI-MCP not installed. Run: pip install fastapi-mcp"
    fi
else
    fail_test "FastAPI requirements.txt not found"
fi

# Test 10: Generate Installation Script
echo -e "\n📝 Generating installation script..."

cat > install-mcp-servers.sh << 'EOF'
#!/bin/bash
# Auto-generated MCP servers installation script

echo "Installing Freight MCP servers..."

# Install Node.js MCP servers
npm install -g @modelcontextprotocol/server-postgres
npm install -g @redis/mcp-redis
npm install -g @modelcontextprotocol/server-docker
npm install -g @modelcontextprotocol/server-github

# Install Python dependencies for FastAPI MCP
if [[ -f "fastapi-integration/requirements.txt" ]]; then
    pip3 install -r fastapi-integration/requirements.txt
fi

echo "MCP servers installation complete!"
echo "Don't forget to:"
echo "1. Set environment variables (DATABASE_URL, REDIS_URL, etc.)"
echo "2. Copy claude-desktop-config.json to your Claude Desktop configuration"
echo "3. Start required services (PostgreSQL, Redis)"
EOF

chmod +x install-mcp-servers.sh
pass_test "Generated install-mcp-servers.sh script"

# Summary
echo -e "\n📊 Test Results Summary"
echo "======================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All critical tests passed! Your MCP setup looks good.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Some tests failed. Please address the issues above.${NC}"
    echo "Run './install-mcp-servers.sh' to install missing MCP servers."
    exit 1
fi