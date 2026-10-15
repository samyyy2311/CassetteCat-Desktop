# Fails when interface text in the QML isn't marked for translation, so new screens don't slip back to English only.
# It checks the plain cases: a text property set straight to a string, on its own line or in a one-line element.
# Run with: cmake -DQML_DIR=<qml folder> -P check_translatable.cmake
cmake_minimum_required(VERSION 3.24)

# Names of products and services stay the same in every language.
set(BRANDS "CassetteCat" "Jellyfin" "Subsonic" "JELLYFIN" "SUBSONIC" "MusicBrainz" "ListenBrainz" "Last.fm" "Libre.fm"
    "LRCLIB" "GitHub" "Deezer" "TheAudioDB" "TagLib" "AutoEq" "Radio Browser" "Cover Art Archive" "Wikipedia" "Qt"
    "MP3" "FLAC" "AAC")
set(PROPERTIES "text|title|subtitle|tooltipText|placeholder|placeholderText|label|accessibleName|Accessible\\.name|titleText|message|confirmText|cancelText|subtitleText|actionLabel")

file(GLOB QML_FILES "${QML_DIR}/*.qml")
set(UNMARKED "")
foreach(QML_FILE ${QML_FILES})
    file(STRINGS "${QML_FILE}" LINES)
    get_filename_component(NAME "${QML_FILE}" NAME)
    foreach(LINE IN LISTS LINES)
        # CMake lists split on semicolons, so they become commas before matching.
        string(REPLACE ";" "," LINE "${LINE}")
        # A property such as `text: "Play"`, alone on its line or followed by `;` or `}`.
        string(REGEX MATCHALL "(^|[{,][ \t]*|^[ \t]*)(${PROPERTIES})[ \t]*:[ \t]*\"[A-Za-z][^\"]*\"[ \t]*($|[,}])" FOUND "${LINE}")
        foreach(MATCH IN LISTS FOUND)
            string(REGEX REPLACE ".*\"([^\"]*)\".*" "\\1" VALUE "${MATCH}")
            if(NOT VALUE IN_LIST BRANDS AND NOT VALUE MATCHES "://")
                string(STRIP "${LINE}" LINE)
                string(APPEND UNMARKED "  ${NAME}: ${LINE}\n")
            endif()
        endforeach()
    endforeach()
endforeach()

if(UNMARKED)
    message(FATAL_ERROR "Interface text isn't marked for translation. Wrap it in qsTr(), see TRANSLATING.md:\n${UNMARKED}")
endif()
