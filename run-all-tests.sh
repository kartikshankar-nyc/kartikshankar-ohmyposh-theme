#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored messages
print_header() {
    echo -e "\n${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}$(printf '=%.0s' {1..70})${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Get the absolute path of the directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Start banner
print_header "Kartik's Oh My Posh Theme - Running All Tests"
echo "Starting test run at: $(date)"
echo "Working directory: $SCRIPT_DIR"
echo ""

# Make all test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Test scripts to run
TEST_SCRIPTS=(
    "test-theme.sh"
    "test-dynamic-segments.sh"
    "test-installation-scripts.sh"
    "test-comprehensive-validation.sh"
)

# Track overall success
ALL_TESTS_PASSED=true

# Run each test script
for script in "${TEST_SCRIPTS[@]}"; do
    script_path="$SCRIPT_DIR/$script"
    
    if [ -f "$script_path" ]; then
        print_header "Running $script"
        
        # Execute the script
        if "$script_path"; then
            print_success "$script completed successfully"
        else
            print_error "$script failed with exit code $?"
            ALL_TESTS_PASSED=false
        fi
    else
        print_error "Test script not found: $script_path"
        ALL_TESTS_PASSED=false
    fi
    
    echo ""
done

# Summary
print_header "Test Run Summary"
echo "Tests completed at: $(date)"

if $ALL_TESTS_PASSED; then
    print_success "All tests completed successfully!"
    echo ""
    echo "Your Oh My Posh theme is ready for use across various platforms and shells."
    echo "It has been verified to:"
    echo "✅ Display the correct OS-specific icons"
    echo "✅ Show the dynamic hostname instead of a hardcoded value"
    echo "✅ Work across multiple shells and platforms with proper installation scripts"
    exit 0
else
    print_error "Some tests failed. Please review the output above."
    echo ""
    echo "Please fix the issues before continuing."
    exit 1
fi 