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