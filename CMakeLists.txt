cmake_minimum_required(VERSION 3.10)
project(PyPokerEvalBinding)

# Détecter le système d'exploitation
if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    if(EXISTS "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/python.exe")
        set(Python3_EXECUTABLE "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/python.exe")
        set(Python3_LIBRARY "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/libs/python311.lib")
        set(Python3_INCLUDE_DIR "$ENV{USERPROFILE}/AppData/Local/Programs/Python/Python311/include")
    elseif(EXISTS "$ENV{USERPROFILE}/Anaconda3/python.exe")
        set(Python3_EXECUTABLE "$ENV{USERPROFILE}/Anaconda3/python.exe")
        set(Python3_LIBRARY "$ENV{USERPROFILE}/Anaconda3/libs/python311.lib")
        set(Python3_INCLUDE_DIR "$ENV{USERPROFILE}/Anaconda3/include")
    else()
        set(Python3_EXECUTABLE "C:/Python311/python.exe")
        set(Python3_LIBRARY "C:/Python311/libs/python311.lib")
        set(Python3_INCLUDE_DIR "C:/Python311/include")
    endif()
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    if(EXISTS "/usr/local/opt/python@3.11/libexec/bin/python3")
        set(Python3_EXECUTABLE "/usr/local/opt/python@3.11/libexec/bin/python3")
        set(Python3_LIBRARY "/usr/local/opt/python@3.11/Frameworks/Python.framework/Versions/3.11/lib/libpython3.11.dylib")
        set(Python3_INCLUDE_DIR "/usr/local/opt/python@3.11/Frameworks/Python.framework/Versions/3.11/include/python3.11")
    elseif(EXISTS "$ENV{HOME}/anaconda3/bin/python3")
        set(Python3_EXECUTABLE "$ENV{HOME}/anaconda3/bin/python3")
        set(Python3_LIBRARY "$ENV{HOME}/anaconda3/lib/libpython3.11.dylib")
        set(Python3_INCLUDE_DIR "$ENV{HOME}/anaconda3/include/python3.11")
    endif()
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    if(EXISTS "/usr/bin/python3")
        set(Python3_EXECUTABLE "/usr/bin/python3")
        set(Python3_LIBRARY "/usr/lib/x86_64-linux-gnu/libpython3.11.so")
        set(Python3_INCLUDE_DIR "/usr/include/python3.11")
    elseif(EXISTS "$ENV{HOME}/anaconda3/bin/python3")
        set(Python3_EXECUTABLE "$ENV{HOME}/anaconda3/bin/python3")
        set(Python3_LIBRARY "$ENV{HOME}/anaconda3/lib/libpython3.11.so")
        set(Python3_INCLUDE_DIR "$ENV{HOME}/anaconda3/include/python3.11")
    endif()
endif()


# Trouver Python 3.x
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

if(Python3_FOUND)
    message(STATUS "Python 3.x trouvé : Version ${Python3_VERSION}")
    message(STATUS "Python Interpreter : ${Python3_EXECUTABLE}")
    message(STATUS "Python Libraries : ${Python3_LIBRARIES}")
    message(STATUS "Python Include Dirs : ${Python3_INCLUDE_DIRS}")

    include_directories(${Python3_INCLUDE_DIRS})
    
    # Configurer les chemins pour poker-eval
    set(POKER_EVAL_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/poker-eval/include")
    include_directories(${POKER_EVAL_INCLUDE_DIR})

    if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
        set(POKER_EVAL_LIB_PATH "${CMAKE_SOURCE_DIR}/poker-eval/build/Debug/poker_lib_static.lib")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        set(POKER_EVAL_LIB_PATH "${CMAKE_SOURCE_DIR}/poker-eval/build/libpoker_lib_static.a")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        set(POKER_EVAL_LIB_PATH "${CMAKE_SOURCE_DIR}/poker-eval/build/libpoker_lib_static.a")
    endif()

    # Vérifier l'existence de la bibliothèque poker-eval
    if(NOT EXISTS ${POKER_EVAL_LIB_PATH})
        message(FATAL_ERROR "La bibliothèque poker-eval n'a pas été trouvée à ${POKER_EVAL_LIB_PATH}. Assurez-vous de la construire d'abord.")
    endif()

    # Ajouter la cible pour pypokereval
    add_library(pypokereval MODULE pypokereval.c)
    target_link_libraries(pypokereval ${Python3_LIBRARIES} ${POKER_EVAL_LIB_PATH})
    
    # Configurer les propriétés de la cible
    set_target_properties(pypokereval PROPERTIES 
        PREFIX ""
        SUFFIX ".so"
    )

    # Définir le nom de sortie en fonction du système d'exploitation
    if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
        set_target_properties(pypokereval PROPERTIES SUFFIX ".pyd")
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        set_target_properties(pypokereval PROPERTIES SUFFIX ".so")
    endif()

    # Afficher des informations de débogage
    message(STATUS "POKER_EVAL_INCLUDE_DIR: ${POKER_EVAL_INCLUDE_DIR}")
    message(STATUS "POKER_EVAL_LIB_PATH: ${POKER_EVAL_LIB_PATH}")

    # Configurer les flags de compilation
    if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        target_compile_options(pypokereval PRIVATE -fPIC)
    endif()

    # Définir les options de débogage si nécessaire
    if(CMAKE_BUILD_TYPE MATCHES Debug)
        target_compile_definitions(pypokereval PRIVATE DEBUG=1)
    endif()

else()
    message(FATAL_ERROR "Python 3.x n'a pas été trouvé. Le binding Python ne peut pas être construit.")
endif()
