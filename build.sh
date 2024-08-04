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
if [ -d "${BASE_PATH}/poker-eval" ]; then
    echo "Removing existing poker-eval directory"
    rm -rf "${BASE_PATH}/poker-eval"
fi
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
    cmake .. -DCMAKE_POSITION_INDEPENDENT_CODE=ON
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
elif [[ "$OS" == "MacOS" ]]; then
    cmake -DPython3_EXECUTABLE=/usr/local/opt/python@3.11/libexec/bin/python3 \
    -DPython3_INCLUDE_DIR=/usr/local/opt/python@3.11/Frameworks/Python.framework/Versions/3.11/include/python3.11 \
    -DPython3_LIBRARY=/usr/local/opt/python@3.11/Frameworks/Python.framework/Versions/3.11/lib/libpython3.11.dylib \
    ..
    make
elif [[ "$OS" == "Linux" ]]; then
    cmake -DPython3_EXECUTABLE=$(which python3.11) -DPython3_INCLUDE_DIR=$(python3.11 -c "from sysconfig import get_paths as gp; print(gp()['include'])") -DPython3_LIBRARY=$(python3.11 -c "from sysconfig import get_config_var as gcv; print(gcv('LIBDIR') + '/libpython3.11.so')") ..
    make
fi

cd "${BASE_PATH}"

if [[ "$OS" == "Windows" ]]; then
    echo "Renaming and moving pypokereval.dll..."
    mv "${BASE_PATH}/build/Debug/pypokereval.dll" "${BASE_PATH}/_pokereval_3_11.pyd"
elif [[ "$OS" == "Linux" ]]; then
    echo "Copying and renaming pypokereval.so..."
    cp "${BASE_PATH}/build/pypokereval.so" "${BASE_PATH}/_pokereval_3_11.so"
elif [[ "$OS" == "MacOS" ]]; then
    echo "Copying and renaming pypokereval.so..."
    cp "${BASE_PATH}/build/pypokereval.so" "${BASE_PATH}/_pokereval_3_11.so"
fi

echo "Build process completed."
