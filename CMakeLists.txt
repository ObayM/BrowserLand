cmake_minimum_required(VERSION 3.21)
project(BrowserLand VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)

find_package(Qt6 6.5 REQUIRED COMPONENTS Gui Qml Quick WebEngineQuick)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(browserland src/main.cpp)

qt_add_qml_module(browserland
    URI BrowserLand
    VERSION 1.0
    QML_FILES qml/Main.qml
)

target_link_libraries(browserland PRIVATE
    Qt6::Gui Qt6::Qml Qt6::Quick Qt6::WebEngineQuick)