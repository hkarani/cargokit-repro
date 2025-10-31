#!/bin/bash

# Script to parse Android configuration from precompile_binaries.yml
WORKFLOW_FILE="src/boltz-dart/.github/workflows/precompiled_binaries.yml"

# Function to check if file exists
check_file() {
    if [ ! -f "$WORKFLOW_FILE" ]; then
        echo "Error: Workflow file not found at $WORKFLOW_FILE"
        exit 1
    fi
}


# Parse using regex with bash
parse_with_bash_regex() {
    echo "=== Parsing with bash regex ==="
    
    # Read the file content
    content=$(cat "$WORKFLOW_FILE")
    
    # Extract NDK version using regex
    if [[ $content =~ --android-ndk-version=([^[:space:]]+) ]]; then
        ndk_version="${BASH_REMATCH[1]}"
        echo "NDK Version: $ndk_version"
    fi
    
    # Extract SDK location using regex
    if [[ $content =~ --android-sdk-location=([^[:space:]]+) ]]; then
        sdk_location="${BASH_REMATCH[1]}"
        echo "SDK Location: $sdk_location"
    fi
    
    # Extract min SDK version using regex
    if [[ $content =~ --android-min-sdk-version=([^[:space:]]+) ]]; then
        min_sdk_version="${BASH_REMATCH[1]}"
        echo "Min SDK Version: $min_sdk_version"
    fi

     # Extract min SDK version using regex
    if [[ $content =~ --tempdir=([^[:space:]]+) ]]; then
        tempdir="${BASH_REMATCH[1]}"
        echo "Temp dir: $tempdir"
    fi
    
cat > .env_build << EOF
NDK_VERSION=$ndk_version
SDK_LOCATION=$sdk_location
MIN_SDK_VERSION=$min_sdk_version
EOF
}


# Method 6: Parse and validate values
parse_and_validate() {
    echo "=== Parsing and validating values ==="
    
    # Extract values
    ndk_version=$(grep -o '--android-ndk-version=[^[:space:]]*' "$WORKFLOW_FILE" | sed 's/--android-ndk-version=//')
    sdk_location=$(grep -o '--android-sdk-location=[^[:space:]]*' "$WORKFLOW_FILE" | sed 's/--android-sdk-location=//')
    min_sdk_version=$(grep -o '--android-min-sdk-version=[^[:space:]]*' "$WORKFLOW_FILE" | sed 's/--android-min-sdk-version=//')
    
    # Validate NDK version format (should be like 26.3.11579264)
    if [[ $ndk_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "✓ NDK Version ($ndk_version) is valid"
    else
        echo "✗ NDK Version ($ndk_version) format is invalid"
    fi
    
    # Validate SDK location (should be a path)
    if [[ $sdk_location =~ ^/.* ]]; then
        echo "✓ SDK Location ($sdk_location) is a valid path"
    else
        echo "✗ SDK Location ($sdk_location) is not a valid path"
    fi
    
    # Validate min SDK version (should be a number)
    if [[ $min_sdk_version =~ ^[0-9]+$ ]]; then
        echo "✓ Min SDK Version ($min_sdk_version) is valid"
    else
        echo "✗ Min SDK Version ($min_sdk_version) is not a valid number"
    fi
    
    echo ""
}

# Main execution
main() {
    check_file
    
    # Run all parsing methods
    parse_with_grep
    parse_with_awk
    parse_with_bash_regex
    parse_and_export
    parse_and_create_config
    parse_and_validate
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -g, --grep     Parse using grep/sed only"
    echo "  -a, --awk      Parse using awk only"
    echo "  -b, --bash     Parse using bash regex only"
    echo ""
}

# Parse command line arguments
case "${1:---all}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -g|--grep)
        check_file
        parse_with_grep
        ;;
    -a|--awk)
        check_file
        parse_with_awk
        ;;
    -b|--bash)
        check_file
        parse_with_bash_regex
        ;;
    -e|--export)
        check_file
        parse_and_export
        ;;
    -c|--config)
        check_file
        parse_and_create_config
        ;;
    -v|--validate)
        check_file
        parse_and_validate
        ;;
    --all)
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
