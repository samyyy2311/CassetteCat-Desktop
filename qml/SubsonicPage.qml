import QtQuick

RemoteServerPage {
    protocol: "subsonic"
    serviceName: "Subsonic"
    serviceLabel: "SUBSONIC"
    serviceColor: "#FF8500"
    description: qsTr("Connect to Navidrome, gonic, or another Subsonic server")
    urlPlaceholder: qsTr("Server URL (for example, 192.168.1.112:4533)")
}
