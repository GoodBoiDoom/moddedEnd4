pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    enum AuthState { Idle, Scanning, NoFace, Matched, Failed }

    property int authState: FaceAuthPanel.Idle
    signal retryRequested()

    implicitWidth: 64
    implicitHeight: 60

    readonly property real _diamondSize: 36
    readonly property real _radius: 6

    function startScan() {
        authState = FaceAuthPanel.Scanning
    }

    function reset() {
        authState = FaceAuthPanel.Idle
    }

    // Diamond body (rotated square with rounded corners)
    Rectangle {
        id: diamondBody
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -4
        width: _diamondSize
        height: _diamondSize
        rotation: 45
        radius: _radius

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        states: [
            State {
                name: "idle"
                when: root.authState === FaceAuthPanel.Idle
                PropertyChanges {
                    diamondBody.color: "transparent"
                    diamondBody.border.color: Appearance.colors.colPrimary
                }
            },
            State {
                name: "scanning"
                when: root.authState === FaceAuthPanel.Scanning
                PropertyChanges {
                    diamondBody.color: "transparent"
                    diamondBody.border.color: Appearance.colors.colPrimary
                }
            },
            State {
                name: "noface"
                when: root.authState === FaceAuthPanel.NoFace
                PropertyChanges {
                    diamondBody.color: "transparent"
                    diamondBody.border.color: Appearance.colors.colSubtext
                }
            },
            State {
                name: "matched"
                when: root.authState === FaceAuthPanel.Matched
                PropertyChanges {
                    diamondBody.color: "#22cc22"
                    diamondBody.border.color: "#22cc22"
                }
            },
            State {
                name: "failed"
                when: root.authState === FaceAuthPanel.Failed
                PropertyChanges {
                    diamondBody.color: "#ff4444"
                    diamondBody.border.color: "#ff4444"
                }
            }
        ]
    }

    // Pupil group (iris ring + pupil dot) — oscillates during scanning
    Item {
        id: pupilGroup
        x: root.width / 2
        y: root.height / 2 - 4

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        states: [
            State {
                name: "visible"
                when: root.authState === FaceAuthPanel.Idle
                      || root.authState === FaceAuthPanel.Scanning
                      || root.authState === FaceAuthPanel.NoFace
                PropertyChanges { pupilGroup.opacity: 1 }
            },
            State {
                name: "hidden"
                when: root.authState === FaceAuthPanel.Matched
                      || root.authState === FaceAuthPanel.Failed
                PropertyChanges { pupilGroup.opacity: 0 }
            }
        ]

        // Iris ring
        Rectangle {
            id: irisRing
            anchors.centerIn: pupilGroup
            width: 11
            height: 11
            radius: 5.5
            color: "transparent"
            border.width: 1.5
            border.color: root.authState === FaceAuthPanel.NoFace
                          ? Appearance.colors.colSubtext
                          : Appearance.colors.colPrimary
        }

        // Pupil dot
        Rectangle {
            anchors.centerIn: irisRing
            width: 4.5
            height: 4.5
            radius: 2.25
            color: root.authState === FaceAuthPanel.NoFace
                   ? Appearance.colors.colSubtext
                   : Appearance.colors.colPrimary
        }

        // Scanning oscillation
        SequentialAnimation {
            id: scanAnim
            loops: Animation.Infinite
            running: root.authState === FaceAuthPanel.Scanning

            NumberAnimation {
                target: pupilGroup
                property: "x"
                from: root.width / 2 - 9
                to: root.width / 2 + 9
                duration: 800
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: pupilGroup
                property: "x"
                from: root.width / 2 + 9
                to: root.width / 2 - 9
                duration: 800
                easing.type: Easing.InOutSine
            }
        }
    }

    // Pulse glow ring during scanning
    Rectangle {
        id: glowRing
        anchors.centerIn: diamondBody
        width: _diamondSize + 10
        height: _diamondSize + 10
        radius: _radius + 4
        rotation: 45
        color: "transparent"
        border.width: 1.5
        border.color: Appearance.colors.colPrimary
        opacity: 0

        SequentialAnimation {
            id: glowAnim
            loops: Animation.Infinite
            running: root.authState === FaceAuthPanel.Scanning

            NumberAnimation {
                target: glowRing
                property: "opacity"
                from: 0.4
                to: 0
                duration: 1000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: glowRing
                property: "opacity"
                from: 0
                to: 0.4
                duration: 1000
                easing.type: Easing.InOutSine
            }
        }
    }

    // "Tap" label for no-face state
    StyledText {
        id: tapLabel
        anchors.top: diamondBody.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Tap"
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.smallest
        visible: root.authState === FaceAuthPanel.NoFace
        opacity: 0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        states: State {
            name: "visible"
            when: root.authState === FaceAuthPanel.NoFace
            PropertyChanges { tapLabel.opacity: 0.7 }
        }
    }

    // Tap area
    MouseArea {
        anchors.fill: parent
        enabled: root.authState !== FaceAuthPanel.Scanning
                && root.authState !== FaceAuthPanel.Matched
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.authState = FaceAuthPanel.Scanning
            root.retryRequested()
        }
    }
}
