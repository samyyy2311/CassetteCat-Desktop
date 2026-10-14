import QtQuick

RemoteServerPage {
    protocol: "jellyfin"
    serviceName: "Jellyfin"
    serviceLabel: "JELLYFIN"
    serviceColor: "#00A4DC"
    description: qsTr("Stream music from your Jellyfin server")
    urlPlaceholder: qsTr("Server URL (for example, 192.168.1.112:8096)")
}
