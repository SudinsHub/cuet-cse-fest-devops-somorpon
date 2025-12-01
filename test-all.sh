#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  DevOps Challenge - Full Test Suite              ║${NC}"
echo -e "${CYAN}║  Testing Both Development and Production         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"

# Function to wait for services to be ready
wait_for_services() {
    local mode=$1
    local max_attempts=30
    local attempt=0
    
    echo -e "${YELLOW}⏳ Waiting for $mode services to be ready...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:5921/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Services are ready!${NC}\n"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo -e "\n${RED}✗ Services failed to start within timeout${NC}\n"
    return 1
}

# Track overall results
DEV_RESULT=1
PROD_RESULT=1

# ==========================================
# Test Development Environment
# ==========================================
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 1: Testing Development Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📦 Starting development environment...${NC}"
make dev-down > /dev/null 2>&1
make dev-up

if wait_for_services "development"; then
    echo -e "${YELLOW}🧪 Running development tests...${NC}\n"
    ./test.sh dev
    DEV_RESULT=$?
else
    echo -e "${RED}❌ Development environment failed to start${NC}\n"
    DEV_RESULT=1
fi

echo -e "\n${YELLOW}🛑 Stopping development environment...${NC}"
make dev-down > /dev/null 2>&1
sleep 3

# ==========================================
# Test Production Environment
# ==========================================
echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  Step 2: Testing Production Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📦 Starting production environment...${NC}"
make prod-down > /dev/null 2>&1
make prod-up

if wait_for_services "production"; then
    echo -e "${YELLOW}🧪 Running production tests...${NC}\n"
    ./test.sh prod
    PROD_RESULT=$?
else
    echo -e "${RED}❌ Production environment failed to start${NC}\n"
    PROD_RESULT=1
fi

echo -e "\n${YELLOW}🛑 Stopping production environment...${NC}"
make prod-down > /dev/null 2>&1

# ==========================================
# Final Summary
# ==========================================
echo -e "\n${CYAN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            FINAL TEST RESULTS                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}\n"

if [ $DEV_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Development Environment: PASSED${NC}"
else
    echo -e "${RED}✗ Development Environment: FAILED${NC}"
fi

if [ $PROD_RESULT -eq 0 ]; then
    echo -e "${GREEN}✓ Production Environment: PASSED${NC}"
else
    echo -e "${RED}✗ Production Environment: FAILED${NC}"
fi

echo ""

if [ $DEV_RESULT -eq 0 ] && [ $PROD_RESULT -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 SUCCESS! Both environments are working!      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}\n"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  WARNING! Some environments failed tests      ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════╝${NC}\n"
    exit 1
fi
