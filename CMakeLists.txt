cmake_minimum_required(VERSION 3.14)

project(label-image VERSION 0.1 LANGUAGES CXX)

#set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(OUTDIR ${PROJECT_SOURCE_DIR}/bin/${CMAKE_SYSTEM_PROCESSOR})

include(ExternalProject)

add_subdirectory(third-part/prism_all)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third-part/cool-retro-term/app)
#include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third-part/cool-retro-term/qmltermwidget/lib)
#include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third-part/cool-retro-term/qmltermwidget/src/)

set(Protobuf_PROTOC_EXECUTABLE /Users/hbb/source/repos/label-image/vcpkg_installed/x64-osx/tools/protobuf/protoc-25.1.0)

find_package(QT NAMES Qt6 Qt5 COMPONENTS Core Quick REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Quick Widgets REQUIRED)
find_package(OpenCV CONFIG REQUIRED)
find_package(prism COMPONENTS qt::core qt::ui container qt::modular)
find_package(fmt CONFIG REQUIRED)


# add subproject qmltermwidget
set(SUBPROJECT_DIR ${CMAKE_SOURCE_DIR}/third-part/cool-retro-term/qmltermwidget)
ExternalProject_Add(
    QMLTermWidget
    SOURCE_DIR ${SUBPROJECT_DIR}
    CONFIGURE_COMMAND ${QT_QMAKE_EXECUTABLE} ${SUBPROJECT_DIR}/qmltermwidget.pro
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND   cp -rf  ${CMAKE_BINARY_DIR}/QMLTermWidget-prefix/src/QMLTermWidget-build/QMLTermWidget  ${OUTDIR}
)


#arm嵌入式板一般不支持opengl,只支持opengl es,nvidia板是例外
set(USING_OPENGLES off)

set(PROJECT_SOURCES
        src/models/app_config.h
        src/models/app_config.cpp

        src/viewmodels/mainviewmodel.h
        src/viewmodels/mainviewmodel.cpp
        src/viewmodels/editProjectDialogViewmodel.h
        src/viewmodels/editProjectDialogViewmodel.cpp

        src/main.cpp
        src/qml.qrc

        third-part/cool-retro-term/app/qml/resources.qrc
        third-part/cool-retro-term/app/monospacefontmanager.cpp
        third-part/cool-retro-term/app/fileio.cpp
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(label-image
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET label-image APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation
else()
    if(ANDROID)
        add_library(label-image SHARED
            ${PROJECT_SOURCES}
        )
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    else()
        add_executable(label-image
          ${PROJECT_SOURCES}
        )
    endif()
endif()

target_compile_definitions(label-image
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
target_link_libraries(label-image
  PRIVATE
  prism
  prism::container
  prism::qt::modular
  prism::qt::core
  prism::qt::ui
  fmt::fmt-header-only
  opencv_core
  opencv_imgcodecs
  opencv_imgproc
  #${CMAKE_BINARY_DIR}/QMLTermWidget-prefix/src/QMLTermWidget-build/QMLTermWidget/libqmltermwidget.dylib

  Qt${QT_VERSION_MAJOR}::Core
  Qt${QT_VERSION_MAJOR}::Widgets
  Qt${QT_VERSION_MAJOR}::Quick)

set_target_properties(label-image PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

# 设置 app 目标的输出路径
set_target_properties(label-image PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY  ${OUTDIR}
)

# 声明自定义命令，用于复制动态库到生成目标目录
add_custom_command(TARGET label-image POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:prism_container>
        $<TARGET_FILE:prism_qt_core>
        $<TARGET_FILE:prism_qt_ui>
        $<TARGET_FILE_DIR:label-image>
)



if(QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(label-image)
    qt_finalize_executable(label-image)
endif()
