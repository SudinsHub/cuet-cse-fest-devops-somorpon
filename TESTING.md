# Testing Guide

This project includes comprehensive testing scripts that validate both development and production environments.

## Quick Start

### Test Current Environment
If you already have dev or prod running:
```bash
# Test development environment
./test.sh dev

# Test production environment
./test.sh prod
```

### Test Both Environments (Complete Test Suite)
Automatically tests both dev and prod environments:
```bash
./test-all.sh
```

This will:
1. Start development environment
2. Run all tests on dev
3. Stop development environment
4. Start production environment
5. Run all tests on prod
6. Stop production environment
7. Show final results

## Manual Testing with Makefile

### Development Environment
```bash
# Start development
make dev-up

# Test development
./test.sh dev

# View logs
make dev-logs

# Stop development
make dev-down
```

### Production Environment
```bash
# Start production
make prod-up

# Test production
./test.sh prod

# View logs
make prod-logs

# Stop production
make prod-down
```

## What Gets Tested

### ✅ Functionality Tests (9 tests)
- Gateway health check
- Backend health check via gateway
- Product creation with valid data
- Product retrieval
- Data persistence verification
- Input validation (empty name)
- Input validation (negative price)
- Input validation (missing fields)
- Multiple product management

### 🔒 Security Tests (1 test)
- Backend isolation (port 3847 should NOT be accessible)

### 🐳 Infrastructure Tests (3 tests)
- All containers running (gateway, backend, mongo)
- Data persistence volumes exist
- Private network isolation

## Test Results

The scripts provide:
- ✓ Green checkmarks for passed tests
- ✗ Red X marks for failed tests
- Detailed error messages
- Final summary with pass/fail counts
- Success rate percentage

## Environment-Specific Testing

Both dev and prod environments are tested with:
- Different container names (`dev-*` vs `prod-*`)
- Different volume names (`dev-*` vs `prod-*`)
- Different network names (`dev-app-network` vs `prod-app-network`)
- Same functionality requirements

## Exit Codes

- `0` - All tests passed
- `1` - Some tests failed

This makes it easy to integrate into CI/CD pipelines.
