#!/bin/bash
# API Testing Script
# This script tests all API endpoints with various scenarios

BASE_URL="http://localhost:3000"
LICENSE_KEY="demo-license-key-12345678"

echo "========================================="
echo "Opera V5 API - Comprehensive Test Suite"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo "1. Testing Health Endpoint (No Auth Required)"
echo "---------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    print_result 0 "Health check returned 200"
    echo "Response: $BODY"
else
    print_result 1 "Health check failed with status $HTTP_CODE"
fi
echo ""

echo "2. Testing GET Guest Without API Key (Should Fail)"
echo "---------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/guests/12345")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 401 ]; then
    print_result 0 "Correctly rejected request without API key (401)"
    echo "Response: $BODY"
else
    print_result 1 "Expected 401, got $HTTP_CODE"
fi
echo ""

echo "3. Testing GET Guest With Invalid API Key (Should Fail)"
echo "--------------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -H "x-api-key: invalid-key" "$BASE_URL/api/guests/12345")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 401 ]; then
    print_result 0 "Correctly rejected invalid API key (401)"
    echo "Response: $BODY"
else
    print_result 1 "Expected 401, got $HTTP_CODE"
fi
echo ""

echo "4. Testing GET Guest With Valid API Key"
echo "----------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -H "x-api-key: $LICENSE_KEY" "$BASE_URL/api/guests/12345")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 404 ]; then
    print_result 0 "API key accepted (status $HTTP_CODE)"
    echo "Response: $BODY"
else
    print_result 1 "Unexpected status $HTTP_CODE"
    echo "Response: $BODY"
fi
echo ""

echo "5. Testing GET Guest With Invalid nameId Format"
echo "------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -H "x-api-key: $LICENSE_KEY" "$BASE_URL/api/guests/abc")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 400 ]; then
    print_result 0 "Correctly rejected invalid nameId format (400)"
    echo "Response: $BODY"
else
    print_result 1 "Expected 400, got $HTTP_CODE"
fi
echo ""

echo "6. Testing PUT Guest Update Without API Key (Should Fail)"
echo "----------------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Content-Type: application/json" \
    -d '{"first_name":"Test"}' \
    "$BASE_URL/api/guests/12345")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 401 ]; then
    print_result 0 "Correctly rejected PUT without API key (401)"
    echo "Response: $BODY"
else
    print_result 1 "Expected 401, got $HTTP_CODE"
fi
echo ""

echo "7. Testing PUT Guest Update With Valid API Key"
echo "-----------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Content-Type: application/json" \
    -H "x-api-key: $LICENSE_KEY" \
    -d '{
        "first_name": "Jane",
        "last_name": "Smith",
        "address": "123 Main Street",
        "doc_type": "PASSPORT",
        "doc_number": "AB123456"
    }' \
    "$BASE_URL/api/guests/12345")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 404 ]; then
    print_result 0 "PUT request accepted (status $HTTP_CODE)"
    echo "Response: $BODY"
else
    print_result 1 "Unexpected status $HTTP_CODE"
    echo "Response: $BODY"
fi
echo ""

echo "8. Testing PUT Guest Update With No Fields (Should Fail)"
echo "---------------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Content-Type: application/json" \
    -H "x-api-key: $LICENSE_KEY" \
    -d '{}' \
    "$BASE_URL/api/guests/12345")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 400 ]; then
    print_result 0 "Correctly rejected empty update (400)"
    echo "Response: $BODY"
else
    print_result 1 "Expected 400, got $HTTP_CODE"
fi
echo ""

echo "9. Testing PUT Guest Update With Invalid confirmationNo"
echo "--------------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
    -H "Content-Type: application/json" \
    -H "x-api-key: $LICENSE_KEY" \
    -d '{"first_name":"Test"}' \
    "$BASE_URL/api/guests/abc")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 400 ]; then
    print_result 0 "Correctly rejected invalid confirmationNo (400)"
    echo "Response: $BODY"
else
    print_result 1 "Expected 400, got $HTTP_CODE"
fi
echo ""

echo "10. Testing Non-Existent Route"
echo "-------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -H "x-api-key: $LICENSE_KEY" "$BASE_URL/api/nonexistent")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 404 ]; then
    print_result 0 "Correctly returned 404 for non-existent route"
    echo "Response: $BODY"
else
    print_result 1 "Expected 404, got $HTTP_CODE"
fi
echo ""

echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi
