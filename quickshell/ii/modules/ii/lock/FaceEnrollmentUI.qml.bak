pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    signal enrollmentComplete(confidence: real)
    signal enrollmentFailed(reason: string)
    
    implicitWidth: 400
    implicitHeight: 500
    
    readonly property string _enrollHelper: "/home/om/linux-hello/scripts/enroll-helper.py"
    
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Title
        StyledText {
            text: "Face Enrollment"
            font.pixelSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnSurface
        }
        
        // Instructions
        StyledText {
            text: "Move your face to capture multiple angles.\nFrames will be captured automatically.\n\nKeep your face centered and well-lit."
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurfaceVariant
            wrapMode: Text.WordWrap
        }
        
        // Progress area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            radius: 12
            color: Appearance.colors.colSurfaceVariant
            
            Column {
                anchors.centerIn: parent
                anchors.margins: 20
                width: parent.width - 40
                spacing: 16
                
                // Status text
                StyledText {
                    id: statusText
                    text: "Initializing..."
                    font.pixelSize: Appearance.font.pixelSize.medium
                    color: Appearance.colors.colOnSurface
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                
                // Frame counter
                StyledText {
                    id: frameCounter
                    text: "Frames: 0/15"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                
                // Progress bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Appearance.colors.colSurfaceContainer
                    width: parent.width
                    
                    Rectangle {
                        id: progressBar
                        height: parent.height
                        radius: 4
                        color: Appearance.colors.colPrimary
                        width: 0
                        
                        Behavior on width {
                            NumberAnimation { duration: 300 }
                        }
                    }
                }
                
                // Diamond eye indicator
                FaceAuthPanel {
                    id: enrollmentEye
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Action buttons
        Row {
            Layout.fillWidth: true
            spacing: 12
            
            RippleButton {
                text: "Cancel"
                Layout.fillWidth: true
                colBackground: Appearance.colors.colErrorContainer
                onClicked: {
                    enrollmentProc.running = false
                    root.enrollmentFailed("cancelled")
                }
            }
            
            RippleButton {
                text: "Start Enrollment"
                Layout.fillWidth: true
                colBackground: Appearance.colors.colPrimaryContainer
                enabled: !enrollmentProc.running
                onClicked: startEnrollment()
            }
        }
    }
    
    Process {
        id: enrollmentProc
        command: ["uv", "run", "--project", "/home/om/linux-hello", "python3", root._enrollHelper]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var lines = output.trim().split("\n")
                    var lastLine = lines[lines.length - 1]
                    if (lastLine.length === 0) {
                        statusText.text = "No output from enrollment"
                        enrollmentEye.authState = FaceAuthPanel.Failed
                        return
                    }
                    var result = JSON.parse(lastLine)
                    
                    if (result.type === "progress") {
                        frameCounter.text = "Frames: " + result.frames_captured + "/" + result.target_frames
                        progressBar.width = (result.frames_captured / result.target_frames) * progressBar.parent.width
                        enrollmentEye.authState = FaceAuthPanel.Scanning
                        statusText.text = "Capturing frame " + result.frames_captured + "/" + result.target_frames
                    } else if (result.type === "complete") {
                        enrollmentEye.authState = FaceAuthPanel.Matched
                        statusText.text = "Enrollment Complete!"
                        frameCounter.text = "Frames: " + result.frames_captured + "/15"
                        root.enrollmentComplete(result.confidence)
                    } else if (result.type === "error") {
                        enrollmentEye.authState = FaceAuthPanel.Failed
                        statusText.text = "Error: " + (result.message || "Unknown error")
                        root.enrollmentFailed(result.message || "unknown_error")
                    }
                } catch (e) {
                    enrollmentEye.authState = FaceAuthPanel.Failed
                    statusText.text = "Parse error: " + e.toString()
                    root.enrollmentFailed("parse_error")
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                console.log("[enroll stderr]", output)
                if (output.trim().length > 0) {
                    statusText.text = "Error occurred (see logs)"
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && enrollmentEye.authState !== FaceAuthPanel.Matched) {
                enrollmentEye.authState = FaceAuthPanel.Failed
                if (statusText.text === "Starting..." || statusText.text === "Initializing...") {
                    statusText.text = "Enrollment failed (exit " + exitCode + ")"
                }
            }
        }
    }
    
    function startEnrollment() {
                        frameCounter.text = "Frames: 0/15"
        progressBar.width = 0
        statusText.text = "Starting..."
        enrollmentEye.authState = FaceAuthPanel.Scanning
        enrollmentProc.running = true
    }
}
