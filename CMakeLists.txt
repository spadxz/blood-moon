cmake_minimum_required(VERSION 3.24)

project(Scarlett
    VERSION 0.17.1
    DESCRIPTION "Scarlett, a lightweight customizable desktop music player"
    LANGUAGES C CXX)

if(WIN32)
    enable_language(RC)
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# the window's title bar on macos is styled through appkit
if(APPLE)
    enable_language(OBJCXX)
    set(CMAKE_OBJCXX_STANDARD 20)
    set(CMAKE_OBJCXX_STANDARD_REQUIRED ON)
endif()

# on windows <cmath> gives M_PI only when asked, and windows.h's min and
# max macros are kept off std::min and std::max; msvc also reads the
# sources as utf-8
if(WIN32)
    add_compile_definitions(_USE_MATH_DEFINES NOMINMAX)
endif()
if(MSVC)
    add_compile_options(/utf-8)
endif()

include(GNUInstallDirs)
include(CTest)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(SCARLETT_IS_LINUX ON)
else()
    set(SCARLETT_IS_LINUX OFF)
endif()

# the wayland, d-bus and pipewire pieces. off elsewhere so the portable parts
# can be built and tested on a development machine without them.
option(SCARLETT_DESKTOP_INTEGRATION "Build the Linux desktop integration" ${SCARLETT_IS_LINUX})
# spotify soloist plays spotify's songs for accounts spotify no longer gives
# librespot the keys for. it is only built for linux.
option(SCARLETT_SOLOIST "Play Spotify songs through Spotify Soloist when it is installed" ${SCARLETT_IS_LINUX})

find_package(Qt6 6.10 REQUIRED COMPONENTS
    Core Gui Network Concurrent Qml Quick QuickControls2 ShaderTools)
if(BUILD_TESTING)
    find_package(Qt6 6.10 REQUIRED COMPONENTS Test QuickTest)
endif()
if(SCARLETT_IS_LINUX)
    find_package(Qt6 6.10 REQUIRED COMPONENTS DBus Widgets)
else()
    find_package(Qt6 6.10 OPTIONAL_COMPONENTS DBus)
endif()
if(SCARLETT_DESKTOP_INTEGRATION)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(PULSE REQUIRED IMPORTED_TARGET libpulse)
endif()
if(SCARLETT_SOLOIST)
    find_package(Qt6 6.10 REQUIRED COMPONENTS WebSockets)
endif()
find_package(Qt6Keychain REQUIRED)
if(WIN32)
    find_package(Qt6 6.10 REQUIRED COMPONENTS Widgets)
endif()
find_package(QCoro6 0.10 REQUIRED COMPONENTS Core Network)
qcoro_enable_coroutines()

qt_standard_project_setup(REQUIRES 6.10)
# modules get their own folder so tooling finds them as <dir>/Scarlett/qmldir,
# clear of the executable (the same name on a case-insensitive disk).
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml_modules)

# --- spotify-core (Rust) -----------------------------------------------------

# the core sits inside this folder in scarlett-linux, and beside it in the
# scarlett repository with the apple apps
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/spotify-core/Cargo.toml)
    set(SCARLETT_CORE_DEFAULT ${CMAKE_CURRENT_SOURCE_DIR}/spotify-core)
else()
    set(SCARLETT_CORE_DEFAULT ${CMAKE_CURRENT_SOURCE_DIR}/../spotify-core)
endif()
set(SCARLETT_CORE_DIR ${SCARLETT_CORE_DEFAULT} CACHE PATH "The Rust core, spotify-core")

include(FetchContent)
FetchContent_Declare(Corrosion
    GIT_REPOSITORY https://github.com/corrosion-rs/corrosion.git
    GIT_TAG v0.6.1)
FetchContent_MakeAvailable(Corrosion)

corrosion_import_crate(
    MANIFEST_PATH ${SCARLETT_CORE_DIR}/Cargo.toml
    CRATE_TYPES staticlib
    NO_DEFAULT_FEATURES
    FEATURES capi)
target_include_directories(spotify_core INTERFACE
    ${SCARLETT_CORE_DIR}/include)
# what rustc reports as the staticlib's native dependencies
# (cargo rustc -- --print native-static-libs).
if(APPLE)
    target_link_libraries(spotify_core INTERFACE
        "-framework AudioToolbox" "-framework CoreAudio" "-framework IOKit"
        "-framework CoreFoundation" "-framework Foundation" "-framework SystemConfiguration"
        "-framework Security" objc iconv)
elseif(WIN32)
    # windows: wasapi for audio, schannel for tls, and what rust's std
    # needs; the linker leaves out any of them nothing uses
    target_link_libraries(spotify_core INTERFACE
        ws2_32 userenv bcrypt ntdll advapi32 kernel32 user32 shell32 ole32 oleaut32
        propsys crypt32 secur32 ncrypt runtimeobject synchronization)
else()
    find_package(ALSA REQUIRED)
    find_package(OpenSSL REQUIRED)
    find_package(Threads REQUIRED)
    target_link_libraries(spotify_core INTERFACE
        ALSA::ALSA OpenSSL::SSL OpenSSL::Crypto Threads::Threads ${CMAKE_DL_LIBS} m)
endif()

# --- material-color-utilities ------------------------------------------------

file(GLOB_RECURSE MCU_SOURCES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/material-color-utilities/cpp/*.cc)
add_library(material_color_utilities STATIC ${MCU_SOURCES})
target_include_directories(material_color_utilities PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/material-color-utilities)
set_target_properties(material_color_utilities PROPERTIES POSITION_INDEPENDENT_CODE ON)

# --- fonts ---------------------------------------------------------------------

option(SCARLETT_DOWNLOAD_ICON_FONT
    "Download Material Symbols Rounded to install beside the app" ON)
include(cmake/DownloadAsset.cmake)
set(SCARLETT_FONT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/fonts)
if(SCARLETT_DOWNLOAD_ICON_FONT)
    set(SCARLETT_ICON_FONT ${SCARLETT_FONT_DIRECTORY}/MaterialSymbolsRounded.ttf)
    scarlett_download_asset(
        "https://raw.githubusercontent.com/google/material-design-icons/737e3324305806514d7909874fa1818ae1808232/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf"
        "${SCARLETT_ICON_FONT}"
        95b24392bb49efd1bc3e92cff4e2452ad094461bab7c97e7d8723fab97e330ca)
    if(NOT APPLE)
        install(FILES ${SCARLETT_ICON_FONT} DESTINATION ${CMAKE_INSTALL_DATADIR}/scarlett/fonts)
    endif()
    # the font's list of names, from the same commit: the tests check every
    # symbol the qml asks for is in it, since a misspelt one shows as text
    set(SCARLETT_ICON_CODEPOINTS ${SCARLETT_FONT_DIRECTORY}/MaterialSymbolsRounded.codepoints)
    if(BUILD_TESTING)
        scarlett_download_asset(
            "https://raw.githubusercontent.com/google/material-design-icons/737e3324305806514d7909874fa1818ae1808232/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.codepoints"
            "${SCARLETT_ICON_CODEPOINTS}"
            225bd09137103cb7746bc93dc08d08764c9f0c3bd04f4b958d4a3c3c19432dd6)
    endif()
endif()

# google sans flex, end4's face: the interface text, and the titles in it
# drawn round, wide and heavy through its variable axes. its licence travels
# with it.
option(SCARLETT_DOWNLOAD_INTERFACE_FONT
    "Download Google Sans Flex to install beside the app" ON)
if(SCARLETT_DOWNLOAD_INTERFACE_FONT)
    set(SCARLETT_INTERFACE_FONT ${SCARLETT_FONT_DIRECTORY}/GoogleSansFlex.ttf)
    set(SCARLETT_INTERFACE_FONT_LICENSE ${SCARLETT_FONT_DIRECTORY}/GoogleSansFlex-OFL.txt)
    set(SCARLETT_GOOGLE_FONTS https://raw.githubusercontent.com/google/fonts/a0e3dbcdc3a3ecfafff3f071159ae0221628922d/ofl/googlesansflex)
    scarlett_download_asset(
        "${SCARLETT_GOOGLE_FONTS}/GoogleSansFlex%5BGRAD,ROND,opsz,slnt,wdth,wght%5D.ttf"
        "${SCARLETT_INTERFACE_FONT}"
        c31a482fbecbf2e07e6890134d20078723aadf732c9b9c6c9a44f86f8265b6fe)
    scarlett_download_asset("${SCARLETT_GOOGLE_FONTS}/OFL.txt"
        "${SCARLETT_INTERFACE_FONT_LICENSE}"
        fc13d69f63e36d284b6e383d4d1463d8ad404f0aa065e57cf961252d51063137)
    if(NOT APPLE)
        install(FILES ${SCARLETT_INTERFACE_FONT} ${SCARLETT_INTERFACE_FONT_LICENSE}
            DESTINATION ${CMAKE_INSTALL_DATADIR}/scarlett/fonts)
    endif()
endif()

# --- the app ---------------------------------------------------------------------

file(GLOB_RECURSE SCARLETT_SOURCES CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    src/*.cpp src/*.h src/*.mm)
list(REMOVE_ITEM SCARLETT_SOURCES src/main.cpp)
if(NOT APPLE)
    list(FILTER SCARLETT_SOURCES EXCLUDE REGEX "^src/system/macos/")
endif()
if(NOT WIN32)
    list(FILTER SCARLETT_SOURCES EXCLUDE REGEX "^src/system/windows/")
endif()
if(NOT SCARLETT_DESKTOP_INTEGRATION)
    list(FILTER SCARLETT_SOURCES EXCLUDE REGEX "^src/system/linux/")
endif()
if(NOT TARGET Qt6::DBus)
    list(FILTER SCARLETT_SOURCES EXCLUDE REGEX "^src/system/dbus/")
endif()
if(NOT SCARLETT_SOLOIST)
    list(FILTER SCARLETT_SOURCES EXCLUDE REGEX "^src/soloist/")
elseif(NOT SCARLETT_DESKTOP_INTEGRATION)
    # routing soloist through scarlett records it with libpulse
    list(FILTER SCARLETT_SOURCES EXCLUDE REGEX "^src/soloist/SoloistAudioRoute")
endif()

file(GLOB_RECURSE SCARLETT_QML CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    qml/*.qml)
file(GLOB SCARLETT_SINGLETONS CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    qml/design/*.qml)
set_source_files_properties(${SCARLETT_SINGLETONS} PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

file(GLOB SCARLETT_SHADERS CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    shaders/*.frag shaders/*.vert)

qt_add_library(scarlett_app STATIC)
qt_add_resources(scarlett_app "scarlett_translations"
    PREFIX "/translations"
    BASE translations
    FILES translations/ru.json)
qt_add_resources(scarlett_app "scarlett_addons"
    PREFIX "/addons"
    BASE addons
    FILES
        addons/lyrics-mini-player/manifest.json
        addons/lyrics-mini-player/LyricsMiniPlayer.qml
        addons/liquid-lyrics/manifest.json
        addons/liquid-lyrics/LiquidLyrics.qml
        addons/oniko-cursor/manifest.json
        addons/oniko-cursor/OnikoCursor.qml)
qt_add_resources(scarlett_app "scarlett_backdrop"
    PREFIX "/images"
    BASE resources
    FILES resources/scarlett-background.png)
qt_add_qml_module(scarlett_app
    URI Scarlett
    VERSION 1.0
    SOURCES ${SCARLETT_SOURCES}
    QML_FILES ${SCARLETT_QML}
    RESOURCES resources/scarlett-icon.png resources/cameo.png
    DEPENDENCIES QtQuick)
# BATCHABLE: the spectrum's material can be merged into the scene graph's
# batches, which needs the extra vertex input qsb adds for it.
qt_add_shaders(scarlett_app "scarlett_shaders"
    BATCHABLE
    PREFIX "/shaders"
    BASE shaders
    FILES ${SCARLETT_SHADERS})

# material 3's shapes as distance fields, for MaterialShape: drawn at build
# time from the vendored rounded-polygon-qmljs (tools/shape_atlas)
# the tool runs during the build, so a cross build (windows from a mac, say)
# takes one built for the machine doing the building
set(SCARLETT_SHAPE_ATLAS_TOOL "" CACHE FILEPATH
    "a shape_atlas built for the build machine, for cross builds")
if(SCARLETT_SHAPE_ATLAS_TOOL)
    set(SCARLETT_SHAPE_ATLAS_COMMAND ${SCARLETT_SHAPE_ATLAS_TOOL})
elseif(CMAKE_CROSSCOMPILING)
    message(FATAL_ERROR "a cross build needs -DSCARLETT_SHAPE_ATLAS_TOOL=<shape_atlas built for this machine>")
else()
    add_executable(shape_atlas tools/shape_atlas/main.cpp tools/shape_atlas/ShapeAtlasLayout.h)
    target_include_directories(shape_atlas PRIVATE tools/shape_atlas)
    target_link_libraries(shape_atlas PRIVATE Qt6::Core Qt6::Gui Qt6::Qml)
    # it runs on every fresh build, so it is optimised even in a debug one
    target_compile_options(shape_atlas PRIVATE $<$<CXX_COMPILER_ID:Clang,AppleClang,GNU>:-O2>)
    set(SCARLETT_SHAPE_ATLAS_COMMAND shape_atlas)
endif()
set(SCARLETT_SHAPE_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/third_party/rounded-polygon-qmljs)
file(GLOB_RECURSE SCARLETT_SHAPE_SOURCES CONFIGURE_DEPENDS ${SCARLETT_SHAPE_LIBRARY}/*.js)
set(SCARLETT_SHAPE_ATLAS ${CMAKE_CURRENT_BINARY_DIR}/shapes/shape_atlas.png)
add_custom_command(OUTPUT ${SCARLETT_SHAPE_ATLAS}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/shapes
    COMMAND ${SCARLETT_SHAPE_ATLAS_COMMAND} ${SCARLETT_SHAPE_LIBRARY} ${SCARLETT_SHAPE_ATLAS}
    DEPENDS ${SCARLETT_SHAPE_ATLAS_COMMAND} ${SCARLETT_SHAPE_SOURCES}
    COMMENT "Drawing the shape atlas")
qt_add_resources(scarlett_app "scarlett_shape_atlas"
    PREFIX "/shapes"
    BASE ${CMAKE_CURRENT_BINARY_DIR}/shapes
    FILES ${SCARLETT_SHAPE_ATLAS})

target_include_directories(scarlett_app PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)
# qmltyperegistrar includes registered headers by file name alone, so every
# folder holding one is searched too. header names stay unique across src/.
set(SCARLETT_SOURCE_DIRECTORIES)
foreach(source IN LISTS SCARLETT_SOURCES)
    get_filename_component(directory ${CMAKE_CURRENT_SOURCE_DIR}/${source} DIRECTORY)
    list(APPEND SCARLETT_SOURCE_DIRECTORIES ${directory})
endforeach()
list(REMOVE_DUPLICATES SCARLETT_SOURCE_DIRECTORIES)
target_include_directories(scarlett_app PRIVATE ${SCARLETT_SOURCE_DIRECTORIES})
# MaterialShapeItem finds a shape's cell the way the atlas tool lays them out
target_include_directories(scarlett_app PRIVATE tools/shape_atlas)
# public so main.cpp, built in the scarlett target, starts mpris and the
# sleep and device monitors
target_compile_definitions(scarlett_app PUBLIC
    SCARLETT_VERSION="${PROJECT_VERSION}"
    $<$<BOOL:${SCARLETT_DESKTOP_INTEGRATION}>:SCARLETT_DESKTOP_INTEGRATION>
    $<$<TARGET_EXISTS:Qt6::DBus>:SCARLETT_HAS_DBUS>)
target_compile_definitions(scarlett_app PRIVATE
    SCARLETT_BUILD_FONT_DIRECTORY="${SCARLETT_FONT_DIRECTORY}")
# main.cpp picks the core, and is built outside scarlett_app
target_compile_definitions(scarlett_app PUBLIC $<$<BOOL:${SCARLETT_SOLOIST}>:SCARLETT_HAS_SOLOIST>)
if(TARGET Qt6::DBus)
    target_link_libraries(scarlett_app PUBLIC Qt6::DBus)
endif()
if(SCARLETT_SOLOIST)
    target_link_libraries(scarlett_app PUBLIC Qt6::WebSockets)
endif()
if(SCARLETT_DESKTOP_INTEGRATION)
    target_link_libraries(scarlett_app PUBLIC PkgConfig::PULSE)
endif()
if(APPLE)
    target_link_libraries(scarlett_app PUBLIC "-framework AppKit" "-framework MediaPlayer" "-framework QuartzCore")
    # now playing holds its objective-c objects with arc
    set_source_files_properties(src/system/macos/NowPlaying.mm src/system/macos/MacWindow.mm
        PROPERTIES COMPILE_OPTIONS -fobjc-arc)
endif()
target_link_libraries(scarlett_app PUBLIC
    Qt6::Core Qt6::Gui Qt6::Network Qt6::Concurrent Qt6::Qml Qt6::Quick Qt6::QuickControls2
    QCoro6::Core QCoro6::Network
    qt6keychain
    material_color_utilities
    spotify_core)

if(WIN32)
    target_link_libraries(scarlett_app PUBLIC Qt6::Widgets comctl32 dwmapi ole32 shell32 uuid runtimeobject)

    # older mingw-w64 headers (qt's bundled mingw 13.1, say) have no
    # SystemMediaTransportControls in windows.media.h; the media controls are
    # left out there, and the taskbar and window styling still build
    include(CheckCXXSourceCompiles)
    set(CMAKE_REQUIRED_LIBRARIES runtimeobject)
    check_cxx_source_compiles([=[
        #ifdef __MINGW32__
        #define ____FIReference_1_boolean_INTERFACE_DEFINED__
        #endif
        #include <windows.h>
        #include <roapi.h>
        #include <windows.media.h>
        #include <systemmediatransportcontrolsinterop.h>
        using Handler = ABI::Windows::Foundation::ITypedEventHandler<
            ABI::Windows::Media::SystemMediaTransportControls *,
            ABI::Windows::Media::SystemMediaTransportControlsButtonPressedEventArgs *>;
        int main()
        {
            ABI::Windows::Media::ISystemMediaTransportControls *controls = nullptr;
            ABI::Windows::Media::IMusicDisplayProperties2 *music = nullptr;
            ISystemMediaTransportControlsInterop *interop = nullptr;
            Handler *handler = nullptr;
            return __uuidof(Handler).Data1 != 0 && !controls && !music && !interop && !handler ? 0 : 1;
        }
    ]=] SCARLETT_HAVE_SMTC)
    unset(CMAKE_REQUIRED_LIBRARIES)
    if(SCARLETT_HAVE_SMTC)
        target_compile_definitions(scarlett_app PRIVATE SCARLETT_HAVE_SMTC)
    else()
        message(WARNING "This toolchain's windows.media.h has no SystemMediaTransportControls, so Scarlett is "
            "building without the Windows media controls (media overlay, lock screen, media keys). "
            "Build with MSVC, or a newer mingw-w64, for them; see the Windows section of README.md.")
    endif()
endif()

qt_add_executable(scarlett src/main.cpp)
target_link_libraries(scarlett PRIVATE scarlett_app scarlett_appplugin)
if(WIN32)
    configure_file(packaging/icons/scarlett.rc.in "${CMAKE_CURRENT_BINARY_DIR}/scarlett.rc" @ONLY)
    target_sources(scarlett PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/scarlett.rc")
endif()
if(SCARLETT_IS_LINUX)
    target_link_libraries(scarlett PRIVATE Qt6::Widgets)
endif()
# a windowed app on windows, with no console window of its own
set_target_properties(scarlett PROPERTIES WIN32_EXECUTABLE ON)
if(MINGW)
    # qt's WinMain shim reads msvcrt's __argc, which a mingw on ucrt (as
    # homebrew's is) lacks; mingw's own start-up calls main() just as well
    set_target_properties(scarlett PROPERTIES qt_no_entrypoint ON)
endif()

# on macos, an app bundle: its own name in the menu bar and the dock, its own
# icon, and an identifier apart from the swift app's (com.addenator.Scarlett)
if(APPLE)
    set(SCARLETT_ICON_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/packaging/icons)
    # the swift app's icon composer icon, compiled as xcode compiles it: an
    # asset catalog that macos 26 draws with its glass and its dark and tinted
    # looks, and an .icns for older systems. without xcode's actool, an .icns
    # made from the rendered pngs instead.
    execute_process(COMMAND xcrun --find actool
        OUTPUT_VARIABLE SCARLETT_ACTOOL OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    if(SCARLETT_ACTOOL)
        set(SCARLETT_ICON_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/icon)
        file(GLOB SCARLETT_ICON_PARTS LIST_DIRECTORIES false CONFIGURE_DEPENDS ${SCARLETT_ICON_SOURCE}/scarlett.icon/*
            ${SCARLETT_ICON_SOURCE}/scarlett.icon/Assets/*)
        add_custom_command(OUTPUT ${SCARLETT_ICON_OUTPUT}/Assets.car ${SCARLETT_ICON_OUTPUT}/scarlett.icns
            COMMAND ${CMAKE_COMMAND} -E make_directory ${SCARLETT_ICON_OUTPUT}
            COMMAND ${SCARLETT_ACTOOL} --compile ${SCARLETT_ICON_OUTPUT} --platform macosx
                --minimum-deployment-target 13.0 --app-icon scarlett
                --output-partial-info-plist ${SCARLETT_ICON_OUTPUT}/icon.plist
                ${SCARLETT_ICON_SOURCE}/scarlett.icon > /dev/null
            DEPENDS ${SCARLETT_ICON_PARTS}
            COMMENT "Compiling the app icon")
        set(SCARLETT_ICON_FILES ${SCARLETT_ICON_OUTPUT}/Assets.car ${SCARLETT_ICON_OUTPUT}/scarlett.icns)
    else()
        set(SCARLETT_ICONSET ${CMAKE_CURRENT_BINARY_DIR}/scarlett.iconset)
        set(SCARLETT_ICNS ${CMAKE_CURRENT_BINARY_DIR}/scarlett.icns)
        add_custom_command(OUTPUT ${SCARLETT_ICNS}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${SCARLETT_ICONSET}
            COMMAND sips -z 16 16 ${SCARLETT_ICON_SOURCE}/scarlett-32.png --out ${SCARLETT_ICONSET}/icon_16x16.png > /dev/null
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-32.png ${SCARLETT_ICONSET}/icon_16x16@2x.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-32.png ${SCARLETT_ICONSET}/icon_32x32.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-64.png ${SCARLETT_ICONSET}/icon_32x32@2x.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-128.png ${SCARLETT_ICONSET}/icon_128x128.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-256.png ${SCARLETT_ICONSET}/icon_128x128@2x.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-256.png ${SCARLETT_ICONSET}/icon_256x256.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-512.png ${SCARLETT_ICONSET}/icon_256x256@2x.png
            COMMAND ${CMAKE_COMMAND} -E copy ${SCARLETT_ICON_SOURCE}/scarlett-512.png ${SCARLETT_ICONSET}/icon_512x512.png
            COMMAND iconutil --convert icns --output ${SCARLETT_ICNS} ${SCARLETT_ICONSET}
            DEPENDS ${SCARLETT_ICON_SOURCE}/scarlett-32.png ${SCARLETT_ICON_SOURCE}/scarlett-64.png
                ${SCARLETT_ICON_SOURCE}/scarlett-128.png ${SCARLETT_ICON_SOURCE}/scarlett-256.png
                ${SCARLETT_ICON_SOURCE}/scarlett-512.png
            COMMENT "Making the app icon")
        set(SCARLETT_ICON_FILES ${SCARLETT_ICNS})
    endif()
    set_source_files_properties(${SCARLETT_ICON_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    target_sources(scarlett PRIVATE ${SCARLETT_ICON_FILES})
    if(SCARLETT_ICON_FONT)
        set_source_files_properties(${SCARLETT_ICON_FONT} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/fonts)
        target_sources(scarlett PRIVATE ${SCARLETT_ICON_FONT})
    endif()
    if(SCARLETT_INTERFACE_FONT)
        set_source_files_properties(${SCARLETT_INTERFACE_FONT} ${SCARLETT_INTERFACE_FONT_LICENSE}
            PROPERTIES MACOSX_PACKAGE_LOCATION Resources/fonts)
        target_sources(scarlett PRIVATE ${SCARLETT_INTERFACE_FONT} ${SCARLETT_INTERFACE_FONT_LICENSE})
    endif()
    set_target_properties(scarlett PROPERTIES
        MACOSX_BUNDLE ON
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/packaging/macos/Info.plist.in
        MACOSX_BUNDLE_BUNDLE_NAME "Scarlett"
        MACOSX_BUNDLE_GUI_IDENTIFIER dev.addenator.Scarlett.Qt
        MACOSX_BUNDLE_ICON_FILE scarlett.icns
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION})
    # the linker signs only the executable; signing the bundle seals the icon
    # and the font in with it, so the whole app checks out. a folder synced by
    # icloud tags files with finder and file-provider attributes, which
    # codesign refuses to seal, so they go first.
    # ad hoc by default. an identity of one's own keeps the signature's
    # requirement the same from build to build, so the keychain hands over
    # the stored logins without asking again after each one
    set(SCARLETT_CODESIGN_IDENTITY "-" CACHE STRING "codesign identity for the app bundle; - signs ad hoc")
    add_custom_command(TARGET scarlett POST_BUILD
        COMMAND xattr -cr $<TARGET_BUNDLE_DIR:scarlett>
        COMMAND codesign --force --sign ${SCARLETT_CODESIGN_IDENTITY} $<TARGET_BUNDLE_DIR:scarlett>
        COMMENT "Signing the app bundle")
endif()

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

install(TARGETS scarlett
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    BUNDLE DESTINATION .)
if(NOT APPLE AND NOT WIN32)
    # the desktop entry's name is the wayland app id (see main.cpp), which is
    # how hyprland and the tray match the window to its icon
    install(FILES packaging/scarlett.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    foreach(size 32 48 64 128 256 512)
        install(FILES packaging/icons/scarlett-${size}.png
            DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/${size}x${size}/apps
            RENAME scarlett.png)
    endforeach()
endif()
