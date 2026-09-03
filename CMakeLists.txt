cmake_minimum_required(VERSION 3.24)

project(CassetteCat VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(MINGW)
    add_compile_options(-Wa,-mbig-obj)
endif()

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 Multimedia Concurrent QuickEffects Network)

qt_standard_project_setup()

qt_add_executable(CassetteCat
    src/main.cpp
    src/app.rc
)
set_property(SOURCE src/app.rc APPEND PROPERTY OBJECT_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/assets/cassettecat_icon.ico"
)
set_target_properties(CassetteCat PROPERTIES AUTOMOC_COMPILER_PREDEFINES OFF)

qt_add_qml_module(CassetteCat
    URI CassetteCat
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/LucideIcon.qml
        qml/TransportButton.qml
        qml/PressDepthIconButton.qml
        qml/AudioSeeker.qml
        qml/VolumeControl.qml
        qml/Cover.qml
        qml/AppToolTip.qml
        qml/SongRow.qml
        qml/SongCard.qml
        qml/ArtistCard.qml
        qml/AlbumCard.qml
        qml/CatalogDetail.qml
        qml/GenreCard.qml
        qml/FolderCard.qml
        qml/SectionHeader.qml
        qml/LibraryRefineSheet.qml
        qml/RefineTextInput.qml
        qml/EmptyState.qml
        qml/SleekScrollBar.qml
        qml/SettingsChoicePill.qml
        qml/SettingsPage.qml
        qml/CreditsView.qml
        qml/AutoScroller.qml
        qml/MiniPlayerWindow.qml
    RESOURCES
        qml/icons/external-link.svg
        qml/icons/globe.svg
        qml/icons/info.svg
        qml/icons/shield.svg
        qml/icons/refresh-cw.svg
        qml/icons/zap.svg
        qml/icons/compass.svg
        qml/icons/sliders-horizontal.svg
        qml/icons/grid-2x2.svg
        qml/icons/rotate-ccw.svg
        qml/icons/arrow-up-down.svg
        qml/icons/clock.svg
        qml/icons/arrow-up.svg
        qml/icons/arrow-down.svg
        qml/icons/folder.svg
        qml/icons/house.svg
        qml/icons/library.svg
        qml/icons/logo.svg
        qml/icons/music.svg
        qml/icons/pause.svg
        qml/icons/play.svg
        qml/icons/play-filled.svg
        qml/icons/radio.svg
        qml/icons/search.svg
        qml/icons/settings.svg
        qml/icons/shuffle.svg
        qml/icons/skip-back.svg
        qml/icons/skip-forward.svg
        qml/icons/volume-1.svg
        qml/icons/volume-2.svg
        qml/icons/volume-x.svg
        qml/icons/heart.svg
        qml/icons/disc.svg
        qml/icons/mic.svg
        qml/icons/audio-lines.svg
        qml/icons/repeat.svg
        qml/icons/repeat-1.svg
        qml/icons/more-vertical.svg
        qml/icons/list-music.svg
        qml/icons/quote.svg
        qml/icons/chevron-down.svg
        qml/icons/x.svg
        qml/icons/panel-left.svg
        qml/icons/pin.svg
        qml/icons/pip.svg
        qml/icons/maximize-2.svg
        qml/icons/minus.svg
        assets/apple-touch-icon.png
        assets/01-orange-headphones.png
        assets/02-black-cat-cassette.png
        assets/cassettecat_icon.png
        assets/cassettecat_icon.ico
        assets/03-cream-cassette-hug.png
        assets/04-gray-dancing-headphones.png
        assets/05-tuxedo-cassette-tail.png
        assets/06-calico-player.png
        assets/cassettecat-pixel-cats-sheet.png
        fonts/space_grotesk_variable.ttf
        fonts/ibm_plex_sans_variable.ttf
        fonts/ibm_plex_mono_regular.ttf
        fonts/ibm_plex_mono_semibold.ttf
        fonts/silkscreen_regular.ttf
        fonts/silkscreen_bold.ttf
        fonts/vt323_regular.ttf
        fonts/monocraft.ttf
)

include(FetchContent)
FetchContent_Declare(
    taglib
    GIT_REPOSITORY https://github.com/taglib/taglib.git
    GIT_TAG v2.0.2
)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(taglib)

target_link_libraries(CassetteCat PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia Qt6::Concurrent Qt6::QuickEffects Qt6::Network tag)
if(WIN32)
    target_link_libraries(CassetteCat PRIVATE dwmapi)
endif()
target_include_directories(CassetteCat PRIVATE
    ${taglib_SOURCE_DIR}
    ${taglib_SOURCE_DIR}/taglib
    ${taglib_SOURCE_DIR}/taglib/toolkit
    ${taglib_SOURCE_DIR}/taglib/mpeg
    ${taglib_SOURCE_DIR}/taglib/mpeg/id3v2
    ${taglib_SOURCE_DIR}/taglib/mpeg/id3v2/frames
    ${taglib_SOURCE_DIR}/taglib/mp4
)
target_compile_definitions(CassetteCat PRIVATE TAGLIB_STATIC)

set_target_properties(CassetteCat PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

include(GNUInstallDirs)

install(TARGETS CassetteCat
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET CassetteCat
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)

install(SCRIPT ${deploy_script})

if(WIN32)
    add_custom_target(deploy
        COMMAND "$<TARGET_FILE_DIR:Qt6::Core>/windeployqt.exe" --qmldir "${CMAKE_CURRENT_SOURCE_DIR}/qml" "$<TARGET_FILE:CassetteCat>"
        DEPENDS CassetteCat
        COMMENT "Deploying Qt runtime libraries with windeployqt"
    )
endif()

include(CTest)

if(BUILD_TESTING)
    add_test(NAME library-scan COMMAND CassetteCat --self-check)
    get_filename_component(MINGW_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
    set_tests_properties(library-scan PROPERTIES
        ENVIRONMENT_MODIFICATION
            "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>"
            "PATH=path_list_prepend:${MINGW_BIN_DIR}"
    )
endif()
