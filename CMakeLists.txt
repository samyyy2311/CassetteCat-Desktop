cmake_minimum_required(VERSION 3.24)
project(CassetteCat VERSION 0.5.1 LANGUAGES CXX)

set(CASSETTECAT_PACKAGE_VERSION "${PROJECT_VERSION}" CACHE STRING "Version used by installers and Linux packages")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(Qt6 6.10 REQUIRED COMPONENTS Quick QuickControls2 Multimedia Concurrent QuickEffects Network Widgets)
if(UNIX AND NOT APPLE)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1)
    find_package(Qt6 REQUIRED COMPONENTS DBus)
endif()

qt_standard_project_setup(REQUIRES 6.10)

set(CassetteCat_PLATFORM_SOURCES)
if(WIN32)
    list(APPEND CassetteCat_PLATFORM_SOURCES src/app.rc)
endif()
if(UNIX AND NOT APPLE)
    list(APPEND CassetteCat_PLATFORM_SOURCES src/mpris_adaptor.h src/mpris_adaptor.cpp)
endif()

qt_add_executable(CassetteCat
    src/main.cpp
    src/app_paths.h
    src/app_paths.cpp
    src/app_settings.h
    src/app_settings.cpp
    src/audio_metadata.h
    src/audio_metadata.cpp
    src/image_cache.h
    src/image_cache.cpp
    src/library_scanner.h
    src/library_scanner.cpp
    src/library_controller.h
    src/library_controller.cpp
    src/player_controller.h
    src/player_controller.cpp
    src/services_controller.h
    src/services_controller.cpp
    src/services_lyrics.cpp
    src/services_artist.cpp
    src/services_scrobble.cpp
    src/services_covers.cpp
    src/credential_vault.h
    src/credential_vault.cpp
    src/streaming.h
    src/streaming.cpp
    src/streaming_library.cpp
    src/remote_track_model.h
    src/remote_track_model.cpp
    src/streaming_protocols.h
    src/streaming_protocols.cpp
    src/smtc_controller.h
    src/smtc_controller.cpp
    src/mpris_controller.h
    src/mpris_controller.cpp
    src/tray_controller.h
    src/tray_controller.cpp
    src/global_shortcut_controller.h
    src/global_shortcut_controller.cpp
    src/network_requests.h
    ${CassetteCat_PLATFORM_SOURCES}
)
if(MINGW)
    target_compile_options(CassetteCat PRIVATE -Wa,-mbig-obj)
endif()
if(WIN32)
    set_property(SOURCE src/app.rc APPEND PROPERTY OBJECT_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/assets/cassettecat_icon.ico"
    )
endif()
set_target_properties(CassetteCat PROPERTIES AUTOMOC_COMPILER_PREDEFINES OFF)

set_source_files_properties(qml/Main.qml PROPERTIES QT_QML_SKIP_CACHEGEN TRUE)

qt_add_qml_module(CassetteCat
    URI CassetteCat
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/NowPlayingDeckControls.qml
        qml/NowPlayingTopBar.qml
        qml/NowPlayingLyricsView.qml
        qml/NowPlayingQueueView.qml
        qml/QueueTrackRow.qml
        qml/TrackContextMenu.qml
        qml/TrackMetadataDialog.qml
        qml/ExpandableSearchBar.qml
        qml/LucideIcon.qml
        qml/HoverMarqueeLabel.qml
        qml/TransportButton.qml
        qml/PressDepthIconButton.qml
        qml/AudioSeeker.qml
        qml/VolumeControl.qml
        qml/Cover.qml
        qml/VinylFallback.qml
        qml/AppToolTip.qml
        qml/SongRow.qml
        qml/SongCard.qml
        qml/ArtistCard.qml
        qml/AlbumCard.qml
        qml/CatalogDetail.qml
        qml/ArtistDetailBody.qml
        qml/AlbumDetailBody.qml
        qml/GenreCard.qml
        qml/FolderCard.qml
        qml/HomeSectionHeader.qml
        qml/HomePage.qml
        qml/ListeningRecordPage.qml
        qml/HomeSongCard.qml
        qml/LibraryPage.qml
        qml/LibraryPlaylistsView.qml
        qml/HomeTrackShelf.qml
        qml/SearchPage.qml
        qml/RadioPage.qml
        qml/RemoteServerPage.qml
        qml/JellyfinPage.qml
        qml/SubsonicPage.qml
        qml/NavItem.qml
        qml/SectionLabel.qml
        qml/LibraryRefineSheet.qml
        qml/RefineTextInput.qml
        qml/EmptyState.qml
        qml/SleekScrollBar.qml
        qml/SettingsNavigationItem.qml
        qml/SettingCard.qml
        qml/SettingRow.qml
        qml/SettingSwitch.qml
        qml/SettingSegmentedControl.qml
        qml/SettingChoiceGroup.qml
        qml/SettingButton.qml
        qml/SettingColorPicker.qml
        qml/SettingDivider.qml
        qml/SettingsPathList.qml
        qml/SettingsLibrarySection.qml
        qml/SettingsAppearanceSection.qml
        qml/SettingsPlaybackSection.qml
        qml/SettingsShortcutsSection.qml
        qml/SettingsDesktopSection.qml
        qml/SettingsLyricsSection.qml
        qml/SettingsScrobbleSection.qml
        qml/CoverSearchPopup.qml
        qml/SettingsNetworkSection.qml
        qml/SettingsBackupSection.qml
        qml/ShortcutCaptureField.qml
        qml/ShortcutDefinitions.qml
        qml/SettingsPage.qml
        qml/CreditsView.qml
        qml/AutoScroller.qml
        qml/MiniPlayerWindow.qml
        qml/MiniPlayerArtView.qml
        qml/MiniPlayerQueueView.qml
        qml/MiniPlayerSubpageHeader.qml
        qml/MiniPlayerLyricsView.qml
        qml/MiniPlayerVolumePill.qml
    RESOURCES
        qml/icons/external-link.svg
        qml/icons/pencil.svg
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
        qml/icons/list.svg
        qml/icons/list-music.svg
        qml/icons/quote.svg
        qml/icons/chevron-down.svg
        qml/icons/chevron-left.svg
        qml/icons/chevron-right.svg
        qml/icons/eye.svg
        qml/icons/eye-off.svg
        qml/icons/x.svg
        qml/icons/panel-left.svg
        qml/icons/pin.svg
        qml/icons/pip.svg
        qml/icons/plug.svg
        qml/icons/log-out.svg
        qml/icons/key-round.svg
        qml/icons/maximize-2.svg
        qml/icons/minus.svg
        qml/icons/jellyfin.svg
        qml/icons/subsonic.svg
        qml/icons/lrclib.svg
        qml/icons/deezer.svg
        qml/icons/theaudiodb.svg
        qml/icons/wikipedia.svg
        qml/icons/musicbrainz.svg
        qml/icons/archive.svg
        qml/icons/listenbrainz.svg
        qml/icons/librefm.svg
        qml/icons/github.svg
        qml/icons/autoeq.svg
        qml/icons/ibm.svg
        qml/icons/gpl.svg
        qml/icons/simpleicons.svg
        qml/icons/lucide.svg
        assets/01-orange-headphones.png
        assets/02-black-cat-cassette.png
        assets/cassettecat_icon.png
        assets/cassettecat_icon.ico
        assets/03-cream-cassette-hug.png
        assets/04-gray-dancing-headphones.png
        assets/05-tuxedo-cassette-tail.png
        assets/06-calico-player.png
        assets/cassettecat-pixel-cats-sheet.png
        assets/vinyl_record.svg
        assets/vinyl_tonearm.svg
        fonts/space_grotesk_variable.ttf
        fonts/ibm_plex_sans_variable.ttf
        fonts/ibm_plex_mono_regular.ttf
        fonts/ibm_plex_mono_semibold.ttf
        fonts/silkscreen_regular.ttf
        fonts/silkscreen_bold.ttf
        fonts/vt323_regular.ttf
        fonts/monocraft.ttf
)

include(CTest)
option(CASSETTECAT_BUILD_TESTING "Build CassetteCat tests" ON)
if(CASSETTECAT_BUILD_TESTING)
    enable_testing()
endif()
set(CASSETTECAT_TAGLIB_SOURCE_DIR "" CACHE PATH "Use a local TagLib source checkout")
if(CASSETTECAT_TAGLIB_SOURCE_DIR AND NOT EXISTS "${CASSETTECAT_TAGLIB_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "CASSETTECAT_TAGLIB_SOURCE_DIR must contain TagLib's CMakeLists.txt")
endif()
set(CASSETTECAT_TAGLIB_BUILD_TESTING "${BUILD_TESTING}")
set(CASSETTECAT_TAGLIB_BUILD_EXAMPLES "${BUILD_EXAMPLES}")
set(CASSETTECAT_BUILD_SHARED_LIBS "${BUILD_SHARED_LIBS}")
set(CASSETTECAT_TAGLIB_AUTOMOC "${CMAKE_AUTOMOC}")

include(FetchContent)
FetchContent_Declare(
    taglib
    GIT_REPOSITORY https://github.com/taglib/taglib.git
    GIT_TAG e3de03501ff66221d1f1f971022b248d5b38ba06 # v2.0.2
)
if(CASSETTECAT_TAGLIB_SOURCE_DIR)
    set(FETCHCONTENT_SOURCE_DIR_TAGLIB "${CASSETTECAT_TAGLIB_SOURCE_DIR}")
endif()
set(BUILD_TESTING OFF)
set(BUILD_EXAMPLES OFF)
set(BUILD_SHARED_LIBS OFF)
set(CMAKE_AUTOMOC OFF)
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME taglib-devel)
FetchContent_MakeAvailable(taglib)
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME runtime)
set(CMAKE_AUTOMOC "${CASSETTECAT_TAGLIB_AUTOMOC}")
set(BUILD_TESTING "${CASSETTECAT_TAGLIB_BUILD_TESTING}")
set(BUILD_EXAMPLES "${CASSETTECAT_TAGLIB_BUILD_EXAMPLES}")
set(BUILD_SHARED_LIBS "${CASSETTECAT_BUILD_SHARED_LIBS}")
if(TARGET tag)
    set_target_properties(tag PROPERTIES AUTOMOC OFF AUTOUIC OFF AUTORCC OFF)
endif()

target_link_libraries(CassetteCat PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia Qt6::Concurrent Qt6::QuickEffects Qt6::Network Qt6::Widgets tag)
if(UNIX AND NOT APPLE)
    target_link_libraries(CassetteCat PRIVATE PkgConfig::LIBSECRET Qt6::DBus)
    target_compile_definitions(CassetteCat PRIVATE CASSETTECAT_HAVE_LIBSECRET=1 CASSETTECAT_HAVE_DBUS=1)
endif()
if(WIN32)
    target_compile_definitions(CassetteCat PRIVATE NOMINMAX)
    target_link_libraries(CassetteCat PRIVATE dwmapi ole32 shell32 shlwapi propsys runtimeobject)
    get_filename_component(windowsSdkRoot
        "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots;KitsRoot10]"
        ABSOLUTE
    )
    file(GLOB cppWinrtIncludeDirs "${windowsSdkRoot}/Include/*/cppwinrt")
    list(SORT cppWinrtIncludeDirs COMPARE NATURAL ORDER DESCENDING)
    list(GET cppWinrtIncludeDirs 0 cppWinrtIncludeDir)
    if(NOT EXISTS "${cppWinrtIncludeDir}/winrt/base.h")
        message(FATAL_ERROR "C++/WinRT headers are required to build CassetteCat on Windows")
    endif()
    set_source_files_properties(src/smtc_controller.cpp PROPERTIES
        INCLUDE_DIRECTORIES
        "${cppWinrtIncludeDir}"
    )
    add_custom_command(TARGET CassetteCat POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:Qt6::Widgets>"
            "$<TARGET_FILE_DIR:CassetteCat>"
    )
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
if(UNIX AND NOT APPLE)
    set_target_properties(CassetteCat PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    )
endif()

include(GNUInstallDirs)

install(TARGETS CassetteCat
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT runtime
)

qt_generate_deploy_qml_app_script(
    TARGET CassetteCat
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)

install(SCRIPT ${deploy_script} COMPONENT runtime)

if(UNIX AND NOT APPLE)
    install(FILES
        packaging/linux/io.github.samyyy2311.CassetteCat.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
        COMPONENT runtime
    )
    install(FILES
        packaging/linux/io.github.samyyy2311.CassetteCat.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo
        COMPONENT runtime
    )
    install(FILES
        assets/cassettecat_icon.png
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps
        RENAME io.github.samyyy2311.CassetteCat.png
        COMPONENT runtime
    )
endif()

if(UNIX AND NOT APPLE)
    include(cmake/Packaging.cmake)
endif()

if(WIN32)
    add_custom_target(deploy
        COMMAND "$<TARGET_FILE_DIR:Qt6::Core>/windeployqt.exe" --release --no-translations --skip-plugin-types qmltooling --qmldir "${CMAKE_CURRENT_SOURCE_DIR}/qml" "$<TARGET_FILE:CassetteCat>"
        DEPENDS CassetteCat
        COMMENT "Deploying Qt runtime libraries with windeployqt"
    )
endif()

if(CASSETTECAT_BUILD_TESTING)
    add_test(NAME library-scan COMMAND CassetteCat --library-self-check)
    add_test(NAME streaming-protocol COMMAND CassetteCat --streaming-self-check)
    add_test(NAME service-cancellation COMMAND CassetteCat --services-self-check)
    add_test(NAME audio-meter COMMAND CassetteCat --player-self-check)
    set_tests_properties(library-scan streaming-protocol service-cancellation audio-meter PROPERTIES
        ENVIRONMENT_MODIFICATION
            "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>"
    )
endif()
