cmake_minimum_required(VERSION 3.21)
project(BrowserLand VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.9 REQUIRED COMPONENTS Core Gui Network Qml Quick Sql WebEngineQuick)
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

qt_add_executable(browserland
    src/main.cpp
    src/browser/Remote.cpp
    src/browser/Remote.h
)
set_source_files_properties(qml/singletons/Browser.qml qml/singletons/Theme.qml qml/singletons/Bookmarks.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(browserland
    URI BrowserLand
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    SOURCES
        src/config/Config.cpp
        src/config/Config.h
        src/config/ConfigWatcher.cpp
        src/config/ConfigWatcher.h
        src/browser/History.cpp
        src/browser/History.h
        src/browser/System.cpp
        src/browser/System.h
        src/browser/Cookies.cpp
        src/browser/Cookies.h
    QML_FILES
        qml/Main.qml
        qml/DefaultShell.qml
        qml/TabStrip.qml
        qml/AddressBar.qml
        qml/IconButton.qml
        qml/WebArea.qml
        qml/WidgetSlot.qml
        qml/UserQml.qml
        qml/ErrorBanner.qml
        qml/Popover.qml
        qml/TextButton.qml
        qml/FindBar.qml
        qml/PermissionPrompt.qml
        qml/DownloadsButton.qml
        qml/NotificationToast.qml
        qml/Icon.qml
        qml/UiText.qml
        qml/Tooltip.qml
        qml/AppMenu.qml
        qml/singletons/Browser.qml
        qml/singletons/Theme.qml
        qml/NewTabPage.qml
        qml/TabSidebar.qml
        qml/SiteInfo.qml
        qml/ContextMenu.qml
        qml/singletons/Bookmarks.qml
        qml/BookmarksBar.qml
        qml/BookmarkEditor.qml
)

target_include_directories(browserland PRIVATE src/config src/browser)

target_link_libraries(browserland PRIVATE
    browserland_config
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::Sql
    Qt6::WebEngineQuick
)
