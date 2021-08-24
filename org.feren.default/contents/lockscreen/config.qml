import QtQuick 2.5
import QtQuick.Controls 2.5 as QQC2
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.12 as Kirigami
import org.kde.kcm 1.5 as KCM

Kirigami.FormLayout {
    property alias cfg_showClock: showClock.checked
    property alias cfg_showMediaControls: showMediaControls.checked
    property bool cfg_showClockDefault: false
    property bool cfg_showMediaControlsDefault: false

    twinFormLayouts: parentLayout

    QQC2.CheckBox {
        id: showClock
        Kirigami.FormData.label: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "verb, to show something", "Show:")
        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Clock")

        KCM.SettingHighlighter {
            highlight: cfg_showClockDefault != cfg_showClock
        }
    }
    QQC2.CheckBox {
        id: showMediaControls
        text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Media Controls")

        KCM.SettingHighlighter {
            highlight: cfg_showMediaControlsDefault != cfg_showMediaControls
        }
    }
}
