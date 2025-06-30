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