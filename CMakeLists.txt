cmake_minimum_required(VERSION 3.21)
project(BrowserLand VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Qml Quick WebEngineQuick)
qt_standard_project_setup()

add_library(browserland_config STATIC
    src/config/ConfigParser.cpp
    src/config/ConfigParser.h
    src/config/ConfigCheck.cpp
    src/config/ConfigCheck.h
)
target_include_directories(browserland_config PUBLIC src)
target_link_libraries(browserland_config PUBLIC Qt6::Core Qt6::Gui)
qt_add_resources(browserland_config defaults
    PREFIX /browserland
    BASE resources
    FILES resources/default.conf
)

qt_add_executable(browserland src/main.cpp)

qt_add_qml_module(browserland
    URI BrowserLand
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    SOURCES
        src/config/Config.cpp
        src/config/Config.h
        src/config/ConfigWatcher.cpp
        src/config/ConfigWatcher.h
    QML_FILES
        qml/Main.qml
        qml/ErrorBanner.qml
)

target_include_directories(browserland PRIVATE src/config)

target_link_libraries(browserland PRIVATE
    browserland_config
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::WebEngineQuick
)