import QtQuick
import QtTest
import "../qml/ThemeColors.js" as ThemeColors

TestCase {
    name: "ThemeColors"

    function test_contrast_matches_wcag() {
        fuzzyCompare(ThemeColors.contrast(Qt.color("#FFFFFF"), Qt.color("#000000")), 21, 0.001)
        fuzzyCompare(ThemeColors.contrast(Qt.color("#777777"), Qt.color("#FFFFFF")), 4.48, 0.01)
        compare(ThemeColors.contrast(Qt.color("#F5F0EC"), Qt.color("#0E0D0C")),
                ThemeColors.contrast(Qt.color("#0E0D0C"), Qt.color("#F5F0EC")))
    }

    function test_theme_reads_colors_and_optional_accent() {
        compare(ThemeColors.parse('{"background":"#0e0d0c","text":"#F5F0EC","textMuted":"#A8A49E"}'),
                { background: "#0E0D0C", text: "#F5F0EC", textMuted: "#A8A49E" })
        compare(ThemeColors.parse('{"background":"#000000","text":"#FFFFFF","textMuted":"#AAAAAA","accent":"#c23b30"}').accent,
                "#C23B30")
    }

    function test_theme_rejects_bad_files() {
        const bad = ["not json", "[]", '{"background":"#000000","text":"#FFFFFF"}',
                     '{"background":"black","text":"#FFFFFF","textMuted":"#AAAAAA"}',
                     '{"background":"#000000","text":"#FFFFFF","textMuted":"#AAAAAA","accent":"#FFF"}']
        for (const text of bad) {
            let failed = false
            try { ThemeColors.parse(text) } catch (error) { failed = true }
            verify(failed, text)
        }
    }
}
