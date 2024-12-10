# Modern C++ Project Generator

A sophisticated bash script that bootstraps modern C++ projects with CMake integration, testing support, and optional popular libraries. Inspired by tools like `create-next-app`, this script provides a streamlined way to start new C++ projects with best practices built in.

## Features

🚀 **Instant Setup**
- Creates a complete C++ project structure in seconds
- Generates all necessary CMake configuration files
- Sets up Git repository with sensible `.gitignore`
- Includes basic test setup with doctest

📚 **Library Integration**
- Interactive library selection interface
- Automatic dependency management via CMake's FetchContent
- Pre-configured support for popular libraries:
  - `{fmt}` - Modern string formatting
  - `spdlog` - Fast C++ logging
  - `nlohmann/json` - JSON for Modern C++
  - `CLI11` - Command line parser
  - `httplib` - HTTP client/server
  - `Eigen` - Linear algebra and matrices
  - `Catch2` - Modern C++ test framework
  - `range-v3` - Range library

🛠️ **Modern C++ Setup**
- C++17 by default
- Comprehensive warning flags
- Proper project structure
- Cross-platform support

## Prerequisites

- Bash shell
- CMake (3.15 or higher)
- Git
- C++17 compatible compiler

## Installation

```bash
# Clone this repository or download the script
curl -O https://raw.githubusercontent.com/yourusername/cpp-project-generator/main/create-cpp-project.sh

# Make the script executable
chmod +x create-cpp-project.sh
```

## Usage

### Basic Usage
```bash
./create-cpp-project.sh my-project
```

### Command Line Options
```bash
# Create project with specific libraries
./create-cpp-project.sh my-project --with-libs fmt,spdlog,json

# Create minimal project without libraries
./create-cpp-project.sh my-project --no-lib

# List available libraries
./create-cpp-project.sh --list-libs

# Show help
./create-cpp-project.sh --help
```

### Project Structure
```
my-project/
├── src/           # Source files
│   ├── main.cpp
│   └── CMakeLists.txt
├── include/       # Header files
├── tests/         # Test files
│   ├── main_test.cpp
│   └── CMakeLists.txt
├── lib/           # Third-party libraries
├── cmake/         # CMake modules
├── build/         # Build directory
├── CMakeLists.txt
└── README.md
```

## Building Your Project

After creating your project:
```bash
cd my-project/build
cmake ..
cmake --build .
```

## Running Tests
```bash
cd build
ctest --output-on-failure
```

## CMake Options

- `BUILD_TESTING`: Enable/disable building tests (default: ON)
- `BUILD_DOCS`: Enable/disable building documentation (default: OFF)
- `ENABLE_WARNINGS_AS_ERRORS`: Treat warnings as errors (default: OFF)

Example:
```bash
cmake -DBUILD_TESTING=OFF -DENABLE_WARNINGS_AS_ERRORS=ON ..
```

## Contributing

Contributions are welcome! Here are some ways you can contribute:
- Report bugs and request features by creating issues
- Submit pull requests for bug fixes and new features
- Improve documentation
- Add support for more libraries
- Share your experience and suggestions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by modern project generators like `create-next-app`
- Built with best practices from the C++ community
- Special thanks to all the library maintainers that make C++ development better

## Notes

- Project names cannot use CMake reserved words (e.g., "test", "install")
- The script requires an active internet connection to download dependencies
- Some libraries might require additional system dependencies

## Support

If you encounter any issues or have questions:
1. Check the existing issues
2. Create a new issue with a detailed description
3. Include your system information and script version
