#!/bin/bash

# Available libraries and their configurations
declare -A LIBRARIES=(
    ["fmt"]="https://github.com/fmtlib/fmt.git|9.1.0|Modern formatting library"
    ["spdlog"]="https://github.com/gabime/spdlog.git|v1.12.0|Fast logging library"
    ["json"]="https://github.com/nlohmann/json.git|v3.11.2|JSON for Modern C++"
    ["cli11"]="https://github.com/CLIUtils/CLI11.git|v2.3.2|Command line parser"
    ["httplib"]="https://github.com/yhirose/cpp-httplib.git|v0.12.1|HTTP client/server library"
    ["eigen"]="https://gitlab.com/libeigen/eigen.git|3.4.0|Linear algebra library"
    ["catch2"]="https://github.com/catchorg/Catch2.git|v3.4.0|Modern testing framework"
    ["range-v3"]="https://github.com/ericniebler/range-v3.git|0.12.0|Range library"
)

# Function to print colored output
print_step() {
    echo -e "\033[0;34m==>\033[0m $1"
}

print_error() {
    echo -e "\033[0;31mError:\033[0m $1"
}

print_success() {
    echo -e "\033[0;32mSuccess:\033[0m $1"
}

# Function to show help
show_help() {
    echo "Usage: $0 <project-name> [options]"
    echo ""
    echo "Options:"
    echo "  --help          Show this help message"
    echo "  --no-lib        Create a bare-bones setup without any libraries"
    echo "  --list-libs     List available libraries"
    echo "  --with-libs     Specify libraries to include (comma-separated)"
    echo ""
    echo "Example:"
    echo "  $0 my-project --with-libs fmt,spdlog,json"
    exit 0
}

# Function to list available libraries
list_libraries() {
    echo "Available libraries:"
    echo ""
    for lib in "${!LIBRARIES[@]}"; do
        IFS="|" read -r url version description <<< "${LIBRARIES[$lib]}"
        printf "%-12s %-10s %s\n" "$lib" "(${version})" "$description"
    done
    exit 0
}

# Function to prompt for library selection
prompt_libraries() {
    local selected_libs=()
    
    # Check if whiptail is available
    if command -v whiptail >/dev/null 2>&1; then
        # Calculate terminal dimensions for better whiptail display
        TERM_ROWS=$(tput lines)
        TERM_COLS=$(tput cols)
        WHIP_HEIGHT=$((TERM_ROWS - 10))
        WHIP_WIDTH=$((TERM_COLS - 20))
        
        # Create array of options for whiptail
        local lib_options=()
        for lib in "${!LIBRARIES[@]}"; do
            IFS="|" read -r url version description <<< "${LIBRARIES[$lib]}"
            lib_options+=("$lib" "$description" "OFF")
        done
        
        # Show whiptail checklist
        selected=$(whiptail --title "Library Selection" \
                          --checklist "Choose libraries to include (SPACE to select/deselect, ENTER to confirm):" \
                          $WHIP_HEIGHT $WHIP_WIDTH $((${#LIBRARIES[@]} + 2)) \
                          "${lib_options[@]}" \
                          3>&1 1>&2 2>&3)
        
        if [ $? -eq 0 ]; then
            # Remove quotes from whiptail output
            selected_libs=$(echo "$selected" | tr -d '"')
            echo "$selected_libs"
        else
            # User cancelled
            echo ""
        fi
    else
        # Fallback to command line prompt
        echo "Select libraries to include (space-separated list):"
        echo ""
        
        # Display available libraries
        for lib in "${!LIBRARIES[@]}"; do
            IFS="|" read -r url version description <<< "${LIBRARIES[$lib]}"
            echo "  $lib - $description"
        done
        
        echo ""
        read -p "Enter libraries to include (or press Enter for none): " selected_libs
        echo "$selected_libs"
    fi
}

# Function to validate project name
validate_project_name() {
    local project_name=$1
    
    # List of reserved CMake names
    local reserved_names=("test" "all" "help" "install" "package" "edit_cache" "rebuild_cache" "clean" "Testing")
    
    # Check for reserved names (case insensitive)
    for reserved in "${reserved_names[@]}"; do
        if [ "${project_name,,}" = "${reserved,,}" ]; then
            print_error "The name '$project_name' is reserved by CMake and cannot be used."
            print_error "Please choose a different project name."
            exit 1
        fi
    done
    
    # Check for invalid characters
    if ! [[ $project_name =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        print_error "Invalid project name: '$project_name'"
        echo "Project name must:"
        echo "  - Start with a letter"
        echo "  - Contain only letters, numbers, underscores, or hyphens"
        exit 1
    fi
    
    # Check length
    if [ ${#project_name} -lt 1 ] || [ ${#project_name} -gt 50 ]; then
        print_error "Project name must be between 1 and 50 characters long"
        exit 1
    fi
}

# Function to create directory structure
create_directory_structure() {
    local project_name=$1
    
    mkdir -p "$project_name"/{src,include,lib,build,tests,cmake}
    
    # Create initial files
    touch "$project_name/src/main.cpp"
    touch "$project_name/tests/main_test.cpp"
    touch "$project_name/.gitignore"
}

# Function to initialize git repository
init_git() {
    local project_name=$1
    
    cd "$project_name"
    git init
    echo "build/" >> .gitignore
    echo "*.o" >> .gitignore
    echo "*.out" >> .gitignore
    echo "CMakeCache.txt" >> .gitignore
    echo "CMakeFiles/" >> .gitignore
    echo "cmake_install.cmake" >> .gitignore
    echo "compile_commands.json" >> .gitignore
    cd ..
}

# Function to create CMake module for dependencies
create_cmake_modules() {
    local project_name=$1
    local selected_libs=$2
    
    # Create FindDependencies.cmake
    cat > "$project_name/cmake/FindDependencies.cmake" << EOF
include(FetchContent)

# Function to fetch and configure external content
function(fetch_dependency NAME GIT_REPO GIT_TAG)
    FetchContent_Declare(
        \${NAME}
        GIT_REPOSITORY \${GIT_REPO}
        GIT_TAG \${GIT_TAG}
    )
    FetchContent_MakeAvailable(\${NAME})
endfunction()

EOF
    
    # Add selected libraries
    if [ ! -z "$selected_libs" ]; then
        for lib in $(echo $selected_libs | tr "," "\n"); do
            if [ -n "${LIBRARIES[$lib]}" ]; then
                IFS="|" read -r url version description <<< "${LIBRARIES[$lib]}"
                echo "# $description" >> "$project_name/cmake/FindDependencies.cmake"
                echo "fetch_dependency(" >> "$project_name/cmake/FindDependencies.cmake"
                echo "    $lib" >> "$project_name/cmake/FindDependencies.cmake"
                echo "    $url" >> "$project_name/cmake/FindDependencies.cmake"
                echo "    $version" >> "$project_name/cmake/FindDependencies.cmake"
                echo ")" >> "$project_name/cmake/FindDependencies.cmake"
                echo "" >> "$project_name/cmake/FindDependencies.cmake"
            fi
        done
    fi
}

# Function to create CMakeLists.txt files
create_cmake_files() {
    local project_name=$1
    
    # Main CMakeLists.txt
    cat > "$project_name/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.15)

# Set project name and version
project(${project_name}
    VERSION 0.1.0
    DESCRIPTION "A modern C++ project"
    LANGUAGES CXX
)

# Include custom modules
list(APPEND CMAKE_MODULE_PATH \${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(FindDependencies)

# Options
option(BUILD_TESTING "Build tests" ON)
option(BUILD_DOCS "Build documentation" OFF)
option(ENABLE_WARNINGS_AS_ERRORS "Treat warnings as errors" OFF)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Add subdirectories
add_subdirectory(src)

# Testing configuration
if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()
EOF

    # Source CMakeLists.txt
    cat > "$project_name/src/CMakeLists.txt" << EOF
# Add executable target
add_executable(\${PROJECT_NAME} main.cpp)

# Add include directories
target_include_directories(\${PROJECT_NAME}
    PRIVATE
        \${PROJECT_SOURCE_DIR}/include
)

# Set warning levels
if(MSVC)
    target_compile_options(\${PROJECT_NAME} PRIVATE /W4)
else()
    target_compile_options(\${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic)
endif()

target_link_libraries(\${PROJECT_NAME}
    PRIVATE
)
EOF

    # Tests CMakeLists.txt
    cat > "$project_name/tests/CMakeLists.txt" << EOF
# Add test executable
add_executable(\${PROJECT_NAME}_tests main_test.cpp)

# Add include directories
target_include_directories(\${PROJECT_NAME}_tests
    PRIVATE
        \${PROJECT_SOURCE_DIR}/include
)

# Register test
add_test(
    NAME \${PROJECT_NAME}_tests
    COMMAND \${PROJECT_NAME}_tests
)
EOF
}

# Function to update CMakeLists.txt with library dependencies
update_cmake_lists() {
  local project_name=$1
  local selected_libs=$2
    
  # Add library dependencies to target_link_libraries
  if [ ! -z "$selected_libs" ]; then
    sed -i "/target_link_libraries.*PRIVATE/a\        # Added dependencies" "$project_name/src/CMakeLists.txt"
    for lib in $(echo $selected_libs | tr "," "\n"); do
      case $lib in
        "fmt")
          sed -i "/# Added dependencies/a\        fmt::fmt" "$project_name/src/CMakeLists.txt"
          ;;
        "spdlog")
          sed -i "/# Added dependencies/a\        spdlog::spdlog" "$project_name/src/CMakeLists.txt"
          ;;
        "json")
          sed -i "/# Added dependencies/a\        nlohmann_json::nlohmann_json" "$project_name/src/CMakeLists.txt"
          ;;
        "cli11")
          sed -i "/# Added dependencies/a\        CLI11::CLI11" "$project_name/src/CMakeLists.txt"
          ;;
        "httplib")
          sed -i "/# Added dependencies/a\        httplib::httplib" "$project_name/src/CMakeLists.txt"
          ;;
        "eigen")
          sed -i "/# Added dependencies/a\        Eigen3::Eigen" "$project_name/src/CMakeLists.txt"
          ;;
        "catch2")
          sed -i "/# Added dependencies/a\        Catch2::Catch2" "$project_name/src/CMakeLists.txt"
          ;;
        "range-v3")
          sed -i "/# Added dependencies/a\        range-v3::range-v3" "$project_name/src/CMakeLists.txt"
          ;;
        esac
    done
  fi
}

# Function to create example code with selected libraries
create_example_code() {
  local project_name=$1
  local selected_libs=$2
    
  # Create the source file
  cat > "$project_name/src/main.cpp" << EOF
/**
 * Main application file for $project_name
 * 
 * This is your project's main entry point.
 * Edit this file at: src/main.cpp
 */

#include <iostream>

EOF
    
  # Add includes for selected libraries
  if [ ! -z "$selected_libs" ]; then
    for lib in $(echo $selected_libs | tr "," "\n"); do
      case $lib in
        "fmt")
          echo "#include <fmt/core.h>" >> "$project_name/src/main.cpp"
          ;;
        "spdlog")
          echo "#include <spdlog/spdlog.h>" >> "$project_name/src/main.cpp"
          ;;
        "json")
          echo "#include <nlohmann/json.hpp>" >> "$project_name/src/main.cpp"
          ;;
        "cli11")
          echo "#include <CLI/CLI.hpp>" >> "$project_name/src/main.cpp"
          ;;
        "httplib")
          echo "#include <httplib.h>" >> "$project_name/src/main.cpp"
          ;;
        "eigen")
          echo "#include <Eigen/Dense>" >> "$project_name/src/main.cpp"
          ;;
        "catch2")
          echo "#include <catch2/catch_all.hpp>" >> "$project_name/src/main.cpp"
          ;;
        "range-v3")
          echo "#include <range/v3/all.hpp>" >> "$project_name/src/main.cpp"
          ;;
      esac
    done
    echo "" >> "$project_name/src/main.cpp"
  fi
    
    # Add main function with example usage and comment
    cat >> "$project_name/src/main.cpp" << EOF
// TODO: Replace this example code with your own
int main() {
    std::cout << "Hello from ${project_name}!" << std::endl;
EOF
    
    # Add example code for selected libraries
    if [ ! -z "$selected_libs" ]; then
        for lib in $(echo $selected_libs | tr "," "\n"); do
            case $lib in
                "fmt")
                    echo "    fmt::print(\"Hello from {fmt}!\\n\");" >> "$project_name/src/main.cpp"
                    ;;
                "spdlog")
                    echo "    spdlog::info(\"Hello from spdlog!\");" >> "$project_name/src/main.cpp"
                    ;;
                "json")
                    echo "    auto j = nlohmann::json::parse(R\"({\"hello\": \"world\"})\");" >> "$project_name/src/main.cpp"
                    echo "    std::cout << \"JSON says: \" << j[\"hello\"] << std::endl;" >> "$project_name/src/main.cpp"
                    ;;
            esac
        done
    fi
    
    echo "" >> "$project_name/src/main.cpp"
    echo "    return 0;" >> "$project_name/src/main.cpp"
    echo "}" >> "$project_name/src/main.cpp"
}

# Function to create initial test file
create_test_file() {
    local project_name=$1
    
    # Download doctest header
    curl -s https://raw.githubusercontent.com/doctest/doctest/master/doctest/doctest.h > "$project_name/include/doctest.h"
    
    cat > "$project_name/tests/main_test.cpp" << EOF
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include "doctest.h"

TEST_CASE("testing basic assertions") {
    CHECK(1 + 1 == 2);
}
EOF
}

# Function to create README
create_readme() {
    local project_name=$1
    local selected_libs=$2
    
    cat > "$project_name/README.md" << EOF
# ${project_name}

A modern C++ project created with create-cpp-project.

## Dependencies

- CMake 3.15 or higher
- C++17 compatible compiler
EOF

    if [ ! -z "$selected_libs" ]; then
        echo -e "\nIncluded libraries:" >> "$project_name/README.md"
        for lib in $(echo $selected_libs | tr "," "\n"); do
            if [ -n "${LIBRARIES[$lib]}" ]; then
                IFS="|" read -r url version description <<< "${LIBRARIES[$lib]}"
                echo "- $lib ($version) - $description" >> "$project_name/README.md"
            fi
        done
    fi

    cat >> "$project_name/README.md" << EOF

## Building

\`\`\`bash
mkdir build && cd build
cmake ..
cmake --build .
\`\`\`

## Running tests

\`\`\`bash
cd build
ctest --output-on-failure
\`\`\`

## Build options

- \`BUILD_TESTING\`: Enable/disable building tests (default: ON)
- \`BUILD_DOCS\`: Enable/disable building documentation (default: OFF)
- \`ENABLE_WARNINGS_AS_ERRORS\`: Treat warnings as errors (default: OFF)

Example:
\`\`\`bash
cmake -DBUILD_TESTING=OFF -DENABLE_WARNINGS_AS_ERRORS=ON ..
\`\`\`
EOF
}

# Main script execution
main() {
    # Parse command line arguments
    local project_name=""
    local no_lib=0
    local selected_libs=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                ;;
            --list-libs)
                list_libraries
                ;;
            --no-lib)
                no_lib=1
                shift
                ;;
            --with-libs)
                selected_libs=$2
                shift 2
                ;;
            *)
                if [ -z "$project_name" ]; then
                    project_name=$1
                    shift
                else
                    print_error "Unknown argument: $1"
                    exit 1
                fi
                ;;
        esac
    done
    
    # Check if project name is provided
    if [ -z "$project_name" ]; then
        print_error "Please provide a project name"
        show_help
    fi

    # Validate project name
    validate_project_name "$project_name"
    
    # If no flags are provided, prompt for library selection
    if [ $no_lib -eq 0 ] && [ -z "$selected_libs" ]; then
        selected_libs=$(prompt_libraries)
    fi
    
    # Check if directory already exists
    if [ -d "$project_name" ]; then
        print_error "Directory $project_name already exists"
        exit 1
    fi
    
    print_step "Creating project structure for $project_name..."
    create_directory_structure "$project_name"
    
    print_step "Initializing git repository..."
    init_git "$project_name"
    
    print_step "Creating CMake modules..."
    create_cmake_modules "$project_name" "$selected_libs"
    
    print_step "Creating CMake configuration..."
    create_cmake_files "$project_name"
    
    print_step "Creating example code..."
    create_example_code "$project_name" "$selected_libs"
    
    print_step "Creating test file..."
    create_test_file "$project_name"
    
    print_step "Creating README..."
    create_readme "$project_name" "$selected_libs"
    
    print_step "Updating CMake configuration for libraries..."
    update_cmake_lists "$project_name" "$selected_libs"
    
    print_success "Project setup complete! To get started:"
    print_success "  cd $project_name"/build
    print_success "  cmake .."
    print_success "  cmake --build ."
    print_success "  ./bin/$project_name"
}

# Run main function
main "$@"