#!/bin/bash

# Arrête le script si une commande échoue
set -e

# Fonction pour détecter l'OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "MacOS";;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) echo "Windows";;
        *)          echo "unknown"
    esac
}

OS=$(detect_os)
echo "Detected OS: $OS"

WORK_DIR=$(pwd)
echo "Working directory: $WORK_DIR"

BASE_PATH="$WORK_DIR"
echo "Base path: $BASE_PATH"

# path to base for Windows
if [ "$OS" = "Windows" ]; then
    BASE_PATH2=$(cygpath -w "$BASE_PATH")
else
    BASE_PATH2="$BASE_PATH"
fi

echo "Adjusted BASE_PATH2 for OS: $BASE_PATH2"

# Initialize submodules
echo "Initializing submodules..."
git submodule update --init --recursive

# Build poker-eval
echo "Building poker-eval..."
cd "${BASE_PATH}/poker-eval"
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: CMakeLists.txt not found in $(pwd)"
    exit 1
fi
mkdir -p build
cd build
if [[ "$OS" == "Windows" ]]; then
    cmake .. -G "Visual Studio 17 2022"
    cmake --build .
elif [[ "$OS" == "Linux" || "$OS" == "MacOS" ]]; then
    cmake ..
    make
fi
cd "${BASE_PATH}"

# Build pypoker-eval
echo "Building pypoker-eval..."
cd "${BASE_PATH}"
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: CMakeLists.txt not found in $(pwd)"
    exit 1
fi
mkdir -p build
cd build
if [[ "$OS" == "Windows" ]]; then
    cmake .. -G "Visual Studio 17 2022"
    cmake --build .
elif [[ "$OS" == "Linux" || "$OS" == "MacOS" ]]; then
    cmake ..
    make
fi
cd "${BASE_PATH}"

if [[ "$OS" == "Windows" ]]; then
    echo "Renaming and moving pypokereval.dll..."
    mv "${BASE_PATH}/build/Debug/pypokereval.dll" "${BASE_PATH}/_pokereval_3_11.pyd"
fi
