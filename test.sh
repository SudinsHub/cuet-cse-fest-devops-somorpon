#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Get mode from argument (dev or prod)
MODE=${1:-dev}

if [ "$MODE" != "dev" ] && [ "$MODE" != "prod" ]; then
    echo -e "${RED}Error: Invalid mode '$MODE'${NC}"
    echo "Usage: $0 [dev|prod]"
    echo "  dev  - Test development environment (default)"
    echo "  prod - Test production environment"
    exit 1
fi

# Set container name prefixes based on mode
if [ "$MODE" = "dev" ]; then
    CONTAINER_PREFIX="dev"
    VOLUME_PREFIX="dev"
    NETWORK_NAME="dev-app-network"
else
    CONTAINER_PREFIX="prod"
    VOLUME_PREFIX="prod"
    NETWORK_NAME="prod-app-network"
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  DevOps Challenge - Testing Script${NC}"
echo -e "${BLUE}  Mode: ${MAGENTA}${MODE^^}${BLUE}${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $2\n"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $2\n"
        ((FAILED++))
    fi
}

# Function to check HTTP response
check_http() {
    local url=$1
    local expected_code=$2
    local description=$3
    
    echo -e "${YELLOW}Testing:${NC} $description"
    echo -e "  URL: $url"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5 --max-time 10 2>/dev/null)
    
    if [ "$response" = "$expected_code" ]; then
        print_result 0 "$description"
        return 0
    else
        echo -e "  Expected: $expected_code, Got: $response"
        print_result 1 "$description"
        return 1
    fi
}

# Function to check JSON response
check_json() {
    local url=$1
    local method=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}Testing:${NC} $description"
    echo -e "  URL: $url"
    echo -e "  Method: $method"
    [ -n "$data" ] && echo -e "  Data: $data"
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -X POST "$url" -H 'Content-Type: application/json' -d "$data" --connect-timeout 5 --max-time 10 2>/dev/null)
    else
        response=$(curl -s "$url" --connect-timeout 5 --max-time 10 2>/dev/null)
    fi
    
    if [ -n "$response" ]; then
        echo -e "  Response: ${response:0:100}..."
        print_result 0 "$description"
        echo "$response"
        return 0
    else
        echo -e "  No response received"
        print_result 1 "$description"
        return 1
    fi
}

# ==========================================
# TEST 1: Gateway Health Check
# ==========================================
check_http "http://localhost:5921/health" "200" "Gateway health check"

# ==========================================
# TEST 2: Backend Health via Gateway
# ==========================================
check_http "http://localhost:5921/api/health" "200" "Backend health check via gateway"

# ==========================================
# TEST 3: Security - Backend NOT directly accessible
# ==========================================
echo -e "${YELLOW}Testing:${NC} Backend should NOT be directly accessible (Security Check)"
echo -e "  URL: http://localhost:3847/api/products"

response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3847/api/products" --connect-timeout 2 --max-time 5 2>/dev/null)

if [ -z "$response" ] || [ "$response" = "000" ] || [ "$response" = "7" ]; then
    print_result 0 "Backend is properly isolated (not accessible from host)"
else
    echo -e "  Backend is accessible with code: $response"
    print_result 1 "Backend should NOT be directly accessible"
fi

# ==========================================
# TEST 4: Create Product with Valid Data
# ==========================================
PRODUCT_RESPONSE=$(check_json "http://localhost:5921/api/products" "POST" '{"name":"Test Product","price":99.99}' "Create product with valid data")

# ==========================================
# TEST 5: Create Another Product
# ==========================================
check_json "http://localhost:5921/api/products" "POST" '{"name":"Another Product","price":49.50}' "Create another product" > /dev/null

# ==========================================
# TEST 6: Get All Products
# ==========================================
PRODUCTS_LIST=$(check_json "http://localhost:5921/api/products" "GET" "" "Get all products")

# Check if products list contains items
if echo "$PRODUCTS_LIST" | grep -q '"name"'; then
    echo -e "${GREEN}✓${NC} Products list contains items\n"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Products list is empty or invalid\n"
    ((FAILED++))
fi

# ==========================================
# TEST 7: Input Validation - Invalid Name
# ==========================================
echo -e "${YELLOW}Testing:${NC} Input validation - empty name should be rejected"
response=$(curl -s -X POST "http://localhost:5921/api/products" \
  -H 'Content-Type: application/json' \
  -d '{"name":"","price":99.99}' --connect-timeout 5 --max-time 10 2>/dev/null)

if echo "$response" | grep -q "error"; then
    echo -e "  Response: $response"
    print_result 0 "Empty name rejected correctly"
else
    echo -e "  Response: $response"
    print_result 1 "Empty name should be rejected"
fi

# ==========================================
# TEST 8: Input Validation - Negative Price
# ==========================================
echo -e "${YELLOW}Testing:${NC} Input validation - negative price should be rejected"
response=$(curl -s -X POST "http://localhost:5921/api/products" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Invalid Product","price":-10}' --connect-timeout 5 --max-time 10 2>/dev/null)

if echo "$response" | grep -q "error"; then
    echo -e "  Response: $response"
    print_result 0 "Negative price rejected correctly"
else
    echo -e "  Response: $response"
    print_result 1 "Negative price should be rejected"
fi

# ==========================================
# TEST 9: Input Validation - Missing Fields
# ==========================================
echo -e "${YELLOW}Testing:${NC} Input validation - missing fields should be rejected"
response=$(curl -s -X POST "http://localhost:5921/api/products" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Only Name"}' --connect-timeout 5 --max-time 10 2>/dev/null)

if echo "$response" | grep -q "error"; then
    echo -e "  Response: $response"
    print_result 0 "Missing price rejected correctly"
else
    echo -e "  Response: $response"
    print_result 1 "Missing price should be rejected"
fi

# ==========================================
# TEST 10: Docker Containers Running
# ==========================================
echo -e "${YELLOW}Testing:${NC} All required Docker containers are running for $MODE mode"

GATEWAY_RUNNING=$(docker ps --filter "name=${CONTAINER_PREFIX}-gateway" --format "{{.Names}}" 2>/dev/null)
BACKEND_RUNNING=$(docker ps --filter "name=${CONTAINER_PREFIX}-backend" --format "{{.Names}}" 2>/dev/null)
MONGO_RUNNING=$(docker ps --filter "name=${CONTAINER_PREFIX}-mongo" --format "{{.Names}}" 2>/dev/null)

if [ -n "$GATEWAY_RUNNING" ] && [ -n "$BACKEND_RUNNING" ] && [ -n "$MONGO_RUNNING" ]; then
    echo -e "  Gateway: $GATEWAY_RUNNING"
    echo -e "  Backend: $BACKEND_RUNNING"
    echo -e "  MongoDB: $MONGO_RUNNING"
    print_result 0 "All $MODE containers are running"
else
    echo -e "  Gateway: ${GATEWAY_RUNNING:-NOT RUNNING}"
    echo -e "  Backend: ${BACKEND_RUNNING:-NOT RUNNING}"
    echo -e "  MongoDB: ${MONGO_RUNNING:-NOT RUNNING}"
    print_result 1 "Some $MODE containers are not running"
fi

# ==========================================
# TEST 11: Docker Volumes Exist (Data Persistence)
# ==========================================
echo -e "${YELLOW}Testing:${NC} Docker volumes exist for data persistence in $MODE mode"

MONGO_VOLUME=$(docker volume ls --filter "name=${VOLUME_PREFIX}-mongo-data" --format "{{.Name}}" 2>/dev/null)

if [ -n "$MONGO_VOLUME" ]; then
    echo -e "  Volume: $MONGO_VOLUME"
    print_result 0 "MongoDB data volume exists for $MODE"
else
    echo -e "  No ${VOLUME_PREFIX}-mongo-data volume found"
    print_result 1 "MongoDB data volume should exist for $MODE"
fi

# ==========================================
# TEST 12: Docker Network Isolation
# ==========================================
echo -e "${YELLOW}Testing:${NC} Private Docker network exists for $MODE mode"

DOCKER_NETWORK=$(docker network ls --filter "name=${NETWORK_NAME}" --format "{{.Name}}" 2>/dev/null)

if [ -n "$DOCKER_NETWORK" ]; then
    echo -e "  Network: $DOCKER_NETWORK"
    print_result 0 "Private Docker network exists for $MODE"
else
    echo -e "  No ${NETWORK_NAME} found"
    print_result 1 "Private Docker network should exist for $MODE"
fi

# ==========================================
# TEST SUMMARY
# ==========================================
TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  TEST SUMMARY - ${MAGENTA}${MODE^^}${BLUE} MODE${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Success Rate: ${PERCENTAGE}%\n"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Your $MODE setup is working correctly!${NC}\n"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please review the errors above.${NC}\n"
    exit 1
fi
