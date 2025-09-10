import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell.Widgets
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Audio

Loader {
  id: lockScreen
  active: false
  signal unlocked

  Timer {
    id: unloadAfterUnlockTimer
    interval: 250
    repeat: false
    onTriggered: {
      lockScreen.active = false
    }
  }

  function scheduleUnloadAfterUnlock() {
    unlocked()
    unloadAfterUnlockTimer.start()
  }

  sourceComponent: Component {
    Item {
      id: lockContainer

      // Create the lock context
      LockContext {
        id: lockContext
        onUnlocked: {
          lockSession.locked = false
          lockScreen.scheduleUnloadAfterUnlock()
          lockContext.currentText = ""
        }
      }

      WlSessionLock {
        id: lockSession
        locked: lockScreen.active

        WlSessionLockSurface {
          readonly property real scaling: ScalingService.dynamicScale(screen)

          Item {
            id: batteryIndicator
            property var battery: UPower.displayDevice
            property bool isReady: battery && battery.ready && battery.isLaptopBattery && battery.isPresent
            property real percent: isReady ? (battery.percentage * 100) : 0
            property bool charging: isReady ? battery.state === UPowerDeviceState.Charging : false
            property bool batteryVisible: isReady && percent > 0
          }

          Item {
            id: keyboardLayout
            property string currentLayout: (typeof KeyboardLayoutService !== 'undefined'
                                            && KeyboardLayoutService.currentLayout) ? KeyboardLayoutService.currentLayout : "Unknown"
          }

          Image {
            id: lockBgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: screen ? WallpaperService.getWallpaper(screen.name) : ""
            cache: true
            smooth: true
            mipmap: false
          }

          Rectangle {
            anchors.fill: parent
            gradient: Gradient {
              GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, 0.6)
              }
              GradientStop {
                position: 0.3
                color: Qt.rgba(0, 0, 0, 0.3)
              }
              GradientStop {
                position: 0.7
                color: Qt.rgba(0, 0, 0, 0.4)
              }
              GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, 0.7)
              }
            }

            Repeater {
              model: 20
              Rectangle {
                width: Math.random() * 4 + 2
                height: width
                radius: width * 0.5
                color: Qt.alpha(Color.mPrimary, 0.3)
                x: Math.random() * parent.width
                y: Math.random() * parent.height

                SequentialAnimation on opacity {
                  loops: Animation.Infinite
                  NumberAnimation {
                    to: 0.8
                    duration: 2000 + Math.random() * 3000
                  }
                  NumberAnimation {
                    to: 0.1
                    duration: 2000 + Math.random() * 3000
                  }
                }
              }
            }
          }

          Item {
            anchors.fill: parent

            ColumnLayout {
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.topMargin: 80 * scaling
              spacing: 40 * scaling

              ColumnLayout {
                spacing: Style.marginXS * scaling
                Layout.alignment: Qt.AlignHCenter

                NText {
                  id: timeText
                  text: Qt.formatDateTime(new Date(), "HH:mm")
                  font.family: Settings.data.ui.fontBillboard
                  font.pointSize: Style.fontSizeXXXL * 6 * scaling
                  font.weight: Style.fontWeightBold
                  font.letterSpacing: -2 * scaling
                  color: Color.mOnSurface
                  horizontalAlignment: Text.AlignHCenter
                  Layout.alignment: Qt.AlignHCenter

                  SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation {
                      to: 1.02
                      duration: 2000
                      easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                      to: 1.0
                      duration: 2000
                      easing.type: Easing.InOutQuad
                    }
                  }
                }

                NText {
                  id: dateText
                  text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                  font.family: Settings.data.ui.fontBillboard
                  font.pointSize: Style.fontSizeXXL * scaling
                  font.weight: Font.Light
                  color: Color.mOnSurface
                  horizontalAlignment: Text.AlignHCenter
                  Layout.alignment: Qt.AlignHCenter
                  Layout.preferredWidth: timeText.implicitWidth
                }
              }

              ColumnLayout {
                spacing: Style.marginM * scaling
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                  Layout.preferredWidth: 108 * scaling
                  Layout.preferredHeight: 108 * scaling
                  Layout.alignment: Qt.AlignHCenter
                  radius: width * 0.5
                  color: Color.transparent
                  border.color: Color.mPrimary
                  border.width: Math.max(1, Style.borderL * scaling)
                  z: 10

                  Loader {
                    active: MediaService.isPlaying && Settings.data.audio.visualizerType == "linear"
                    anchors.centerIn: parent
                    width: 160 * scaling
                    height: 160 * scaling
                    sourceComponent: Item {
                      Repeater {
                        model: CavaService.values.length
                        Rectangle {
                          property real linearAngle: (index / CavaService.values.length) * 2 * Math.PI
                          property real linearRadius: 70 * scaling
                          property real linearBarLength: Math.max(2, CavaService.values[index] * 30 * scaling)
                          property real linearBarWidth: 3 * scaling
                          width: linearBarWidth
                          height: linearBarLength
                          color: Color.mPrimary
                          radius: linearBarWidth * 0.5
                          x: parent.width * 0.5 + Math.cos(linearAngle) * linearRadius - width * 0.5
                          y: parent.height * 0.5 + Math.sin(linearAngle) * linearRadius - height * 0.5
                          transform: Rotation {
                            origin.x: linearBarWidth * 0.5
                            origin.y: linearBarLength * 0.5
                            angle: (linearAngle * 180 / Math.PI) + 90
                          }
                        }
                      }
                    }
                  }

                  Loader {
                    active: MediaService.isPlaying && Settings.data.audio.visualizerType == "mirrored"
                    anchors.centerIn: parent
                    width: 160 * scaling
                    height: 160 * scaling
                    sourceComponent: Item {
                      Repeater {
                        model: CavaService.values.length * 2
                        Rectangle {
                          property int mirroredValueIndex: index < CavaService.values.length ? index : (CavaService.values.length
                                                                                                        * 2 - 1 - index)
                          property real mirroredAngle: (index / (CavaService.values.length * 2)) * 2 * Math.PI
                          property real mirroredRadius: 70 * scaling
                          property real mirroredBarLength: Math.max(
                                                             2, CavaService.values[mirroredValueIndex] * 30 * scaling)
                          property real mirroredBarWidth: 3 * scaling
                          width: mirroredBarWidth
                          height: mirroredBarLength
                          color: Color.mPrimary
                          radius: mirroredBarWidth * 0.5
                          x: parent.width * 0.5 + Math.cos(mirroredAngle) * mirroredRadius - width * 0.5
                          y: parent.height * 0.5 + Math.sin(mirroredAngle) * mirroredRadius - height * 0.5
                          transform: Rotation {
                            origin.x: mirroredBarWidth * 0.5
                            origin.y: mirroredBarLength * 0.5
                            angle: (mirroredAngle * 180 / Math.PI) + 90
                          }
                        }
                      }
                    }
                  }

                  Loader {
                    active: MediaService.isPlaying && Settings.data.audio.visualizerType == "wave"
                    anchors.centerIn: parent
                    width: 160 * scaling
                    height: 160 * scaling
                    sourceComponent: Item {
                      Canvas {
                        id: waveCanvas
                        anchors.fill: parent
                        antialiasing: true
                        onPaint: {
                          var ctx = getContext("2d")
                          ctx.reset()
                          if (CavaService.values.length === 0)
                            return
                          ctx.strokeStyle = Color.mPrimary
                          ctx.lineWidth = 2 * scaling
                          ctx.lineCap = "round"
                          var centerX = width * 0.5
                          var centerY = height * 0.5
                          var baseRadius = 60 * scaling
                          var maxAmplitude = 20 * scaling
                          ctx.beginPath()
                          for (var i = 0; i <= CavaService.values.length; i++) {
                            var index = i % CavaService.values.length
                            var angle = (i / CavaService.values.length) * 2 * Math.PI
                            var amplitude = CavaService.values[index] * maxAmplitude
                            var radius = baseRadius + amplitude
                            var x = centerX + Math.cos(angle) * radius
                            var y = centerY + Math.sin(angle) * radius
                            if (i === 0)
                              ctx.moveTo(x, y)
                            else
                              ctx.lineTo(x, y)
                          }
                          ctx.closePath()
                          ctx.stroke()
                        }
                      }
                      Timer {
                        interval: 16
                        running: true
                        repeat: true
                        onTriggered: waveCanvas.requestPaint()
                      }
                    }
                  }

                  Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 24 * scaling
                    height: parent.height + 24 * scaling
                    radius: width * 0.5
                    color: Color.transparent
                    border.color: Qt.alpha(Color.mPrimary, 0.3)
                    border.width: Math.max(1, Style.borderM * scaling)
                    z: -1
                    visible: !MediaService.isPlaying
                    SequentialAnimation on scale {
                      loops: Animation.Infinite
                      NumberAnimation {
                        to: 1.1
                        duration: 1500
                        easing.type: Easing.InOutQuad
                      }
                      NumberAnimation {
                        to: 1.0
                        duration: 1500
                        easing.type: Easing.InOutQuad
                      }
                    }
                  }

                  NImageCircled {
                    anchors.centerIn: parent
                    width: 100 * scaling
                    height: 100 * scaling
                    imagePath: Settings.data.general.avatarImage
                    fallbackIcon: "person"
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.scale = 1.05
                    onExited: parent.scale = 1.0
                  }

                  Behavior on scale {
                    NumberAnimation {
                      duration: Style.animationFast
                      easing.type: Easing.OutBack
                    }
                  }
                }
              }
            }

            Item {
              width: 720 * scaling
              height: 280 * scaling
              anchors.centerIn: parent
              anchors.verticalCenterOffset: 50 * scaling

              Rectangle {
                id: terminalBackground
                anchors.fill: parent
                radius: Style.radiusM * scaling
                color: Qt.alpha(Color.mSurface, 0.9)
                border.color: Color.mPrimary
                border.width: Math.max(1, Style.borderM * scaling)

                Repeater {
                  model: 20
                  Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.alpha(Color.mPrimary, 0.1)
                    y: index * 10 * scaling
                    opacity: Style.opacityMedium
                    SequentialAnimation on opacity {
                      loops: Animation.Infinite
                      NumberAnimation {
                        to: 0.6
                        duration: 2000 + Math.random() * 1000
                      }
                      NumberAnimation {
                        to: 0.1
                        duration: 2000 + Math.random() * 1000
                      }
                    }
                  }
                }

                Rectangle {
                  width: parent.width
                  height: 40 * scaling
                  color: Qt.alpha(Color.mPrimary, 0.2)
                  topLeftRadius: Style.radiusS * scaling
                  topRightRadius: Style.radiusS * scaling

                  RowLayout {
                    anchors.fill: parent
                    anchors.topMargin: Style.marginM * scaling
                    anchors.bottomMargin: Style.marginM * scaling
                    anchors.leftMargin: Style.marginL * scaling
                    anchors.rightMargin: Style.marginL * scaling
                    spacing: Style.marginL * scaling

                    NText {
                      text: "SECURE TERMINAL"
                      color: Color.mOnSurface
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                      font.weight: Style.fontWeightBold
                      Layout.fillWidth: true
                    }

                    RowLayout {
                      spacing: Style.marginS * scaling
                      NText {
                        text: keyboardLayout.currentLayout
                        color: Color.mOnSurface
                        font.family: Settings.data.ui.fontFixed
                        font.pointSize: Style.fontSizeM * scaling
                        font.weight: Style.fontWeightBold
                      }
                      NIcon {
                        icon: "keyboard"
                        font.pointSize: Style.fontSizeM * scaling
                        color: Color.mOnSurface
                      }
                    }

                    RowLayout {
                      spacing: Style.marginS * scaling
                      visible: batteryIndicator.batteryVisible
                      NIcon {
                        icon: BatteryService.getIcon(batteryIndicator.percent, batteryIndicator.charging,
                                                     batteryIndicator.isReady)
                        font.pointSize: Style.fontSizeM * scaling
                        color: batteryIndicator.charging ? Color.mPrimary : Color.mOnSurface
                        rotation: -90
                      }
                      NText {
                        text: Math.round(batteryIndicator.percent) + "%"
                        color: Color.mOnSurface
                        font.family: Settings.data.ui.fontFixed
                        font.pointSize: Style.fontSizeM * scaling
                        font.weight: Style.fontWeightBold
                      }
                    }
                  }
                }

                ColumnLayout {
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  anchors.margins: Style.marginL * scaling
                  anchors.topMargin: 70 * scaling
                  spacing: Style.marginM * scaling

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM * scaling

                    NText {
                      text: Quickshell.env("USER") + "@noctalia:~$"
                      color: Color.mPrimary
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                      font.weight: Style.fontWeightBold
                    }

                    NText {
                      id: welcomeText
                      text: ""
                      color: Color.mOnSurface
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                      property int currentIndex: 0
                      property string fullText: "Welcome back, " + Quickshell.env("USER") + "!"

                      Timer {
                        interval: Style.animationFast
                        running: true
                        repeat: true
                        onTriggered: {
                          if (parent.currentIndex < parent.fullText.length) {
                            parent.text = parent.fullText.substring(0, parent.currentIndex + 1)
                            parent.currentIndex++
                          } else {
                            running = false
                          }
                        }
                      }
                    }
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM * scaling

                    NText {
                      text: Quickshell.env("USER") + "@noctalia:~$"
                      color: Color.mPrimary
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                      font.weight: Style.fontWeightBold
                    }

                    NText {
                      text: "sudo unlock-session"
                      color: Color.mOnSurface
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                    }

                    TextInput {
                      id: passwordInput
                      width: 0
                      height: 0
                      visible: false
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                      color: Color.mOnSurface
                      echoMode: TextInput.Password
                      passwordCharacter: "*"
                      passwordMaskDelay: 0

                      text: lockContext.currentText
                      onTextChanged: {
                        lockContext.currentText = text
                      }

                      Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                          lockContext.tryUnlock()
                        }
                      }

                      Component.onCompleted: {
                        forceActiveFocus()
                      }
                    }

                    NText {
                      id: asterisksText
                      text: "*".repeat(passwordInput.text.length)
                      color: Color.mOnSurface
                      font.family: Settings.data.ui.fontFixed
                      font.pointSize: Style.fontSizeL * scaling
                      visible: passwordInput.activeFocus

                      SequentialAnimation {
                        id: typingEffect
                        NumberAnimation {
                          target: passwordInput
                          property: "scale"
                          to: 1.01
                          duration: 50
                        }
                        NumberAnimation {
                          target: passwordInput
                          property: "scale"
                          to: 1.0
                          duration: 50
                        }
                      }
                    }

                    Rectangle {
                      width: 8 * scaling
                      height: 20 * scaling
                      color: Color.mPrimary
                      visible: passwordInput.activeFocus
                      Layout.leftMargin: -Style.marginS * scaling
                      Layout.alignment: Qt.AlignVCenter

                      SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation {
                          to: 1.0
                          duration: 500
                        }
                        NumberAnimation {
                          to: 0.0
                          duration: 500
                        }
                      }
                    }
                  }

                  NText {
                    text: {
                      if (lockContext.unlockInProgress)
                        return "Authenticating..."
                      if (lockContext.showFailure && lockContext.errorMessage)
                        return lockContext.errorMessage
                      if (lockContext.showFailure)
                        return "Authentication failed."
                      return ""
                    }
                    color: {
                      if (lockContext.unlockInProgress)
                        return Color.mPrimary
                      if (lockContext.showFailure)
                        return Color.mError
                      return Color.transparent
                    }
                    font.family: "DejaVu Sans Mono"
                    font.pointSize: Style.fontSizeL * scaling
                    Layout.fillWidth: true

                    SequentialAnimation on opacity {
                      running: lockContext.unlockInProgress
                      loops: Animation.Infinite
                      NumberAnimation {
                        to: 1.0
                        duration: 800
                      }
                      NumberAnimation {
                        to: 0.5
                        duration: 800
                      }
                    }
                  }

                  RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.bottomMargin: -10 * scaling
                    Rectangle {
                      Layout.preferredWidth: 120 * scaling
                      Layout.preferredHeight: 40 * scaling
                      radius: Style.radiusS * scaling
                      color: executeButtonArea.containsMouse ? Color.mPrimary : Qt.alpha(Color.mPrimary, 0.2)
                      border.color: Color.mPrimary
                      border.width: Math.max(1, Style.borderS * scaling)
                      enabled: !lockContext.unlockInProgress

                      NText {
                        anchors.centerIn: parent
                        text: lockContext.unlockInProgress ? "EXECUTING" : "EXECUTE"
                        color: executeButtonArea.containsMouse ? Color.mOnPrimary : Color.mPrimary
                        font.family: Settings.data.ui.fontFixed
                        font.pointSize: Style.fontSizeM * scaling
                        font.weight: Style.fontWeightBold
                      }

                      MouseArea {
                        id: executeButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                          lockContext.tryUnlock()
                        }

                        SequentialAnimation on scale {
                          running: executeButtonArea.containsMouse
                          NumberAnimation {
                            to: 1.05
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                          }
                        }

                        SequentialAnimation on scale {
                          running: !executeButtonArea.containsMouse
                          NumberAnimation {
                            to: 1.0
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                          }
                        }
                      }

                      SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: lockContext.unlockInProgress
                        NumberAnimation {
                          to: 1.02
                          duration: 600
                          easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                          to: 1.0
                          duration: 600
                          easing.type: Easing.InOutQuad
                        }
                      }
                    }
                  }
                }

                Rectangle {
                  anchors.fill: parent
                  radius: parent.radius
                  color: Color.transparent
                  border.color: Qt.alpha(Color.mPrimary, 0.3)
                  border.width: Math.max(1, Style.borderS * scaling)
                  z: -1

                  SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                      to: 0.6
                      duration: 2000
                      easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                      to: 0.2
                      duration: 2000
                      easing.type: Easing.InOutQuad
                    }
                  }
                }
              }
            }

            // Power buttons at bottom right
            RowLayout {
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: 50 * scaling
              spacing: 20 * scaling

              // Shutdown
              Rectangle {
                Layout.preferredWidth: iconPower.implicitWidth + Style.marginXL * scaling
                Layout.preferredHeight: Layout.preferredWidth
                radius: width * 0.5
                color: powerButtonArea.containsMouse ? Color.mError : Qt.alpha(Color.mError, 0.2)
                border.color: Color.mError
                border.width: Math.max(1, Style.borderM * scaling)

                NIcon {
                  id: iconPower
                  anchors.centerIn: parent
                  icon: "shutdown"
                  font.pointSize: Style.fontSizeXXXL * scaling
                  color: powerButtonArea.containsMouse ? Color.mOnError : Color.mError
                }

                // Tooltip (inline rectangle to avoid separate Window during lock)
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.top
                  anchors.bottomMargin: 12 * scaling
                  radius: Style.radiusM * scaling
                  color: Color.mSurface
                  border.color: Color.mOutline
                  border.width: Math.max(1, Style.borderS * scaling)
                  visible: powerButtonArea.containsMouse
                  z: 1
                  NText {
                    id: shutdownTooltipText
                    anchors.margins: Style.marginM * scaling
                    anchors.fill: parent
                    text: "Shut down the computer."
                    font.pointSize: Style.fontSizeM * scaling
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                  }
                  implicitWidth: shutdownTooltipText.implicitWidth + Style.marginM * 2 * scaling
                  implicitHeight: shutdownTooltipText.implicitHeight + Style.marginM * 2 * scaling
                }

                MouseArea {
                  id: powerButtonArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    CompositorService.shutdown()
                  }
                }
              }

              // Reboot
              Rectangle {
                Layout.preferredWidth: iconReboot.implicitWidth + Style.marginXL * scaling
                Layout.preferredHeight: Layout.preferredWidth
                radius: width * 0.5
                color: restartButtonArea.containsMouse ? Color.mPrimary : Qt.alpha(Color.mPrimary, Style.opacityLight)
                border.color: Color.mPrimary
                border.width: Math.max(1, Style.borderM * scaling)

                NIcon {
                  id: iconReboot
                  anchors.centerIn: parent
                  icon: "reboot"
                  font.pointSize: Style.fontSizeXXXL * scaling
                  color: restartButtonArea.containsMouse ? Color.mOnPrimary : Color.mPrimary
                }

                // Tooltip
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.top
                  anchors.bottomMargin: 12 * scaling
                  radius: Style.radiusM * scaling
                  color: Color.mSurface
                  border.color: Color.mOutline
                  border.width: Math.max(1, Style.borderS * scaling)
                  visible: restartButtonArea.containsMouse
                  z: 1
                  NText {
                    id: restartTooltipText
                    anchors.margins: Style.marginM * scaling
                    anchors.fill: parent
                    text: "Restart the computer."
                    font.pointSize: Style.fontSizeM * scaling
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                  }
                  implicitWidth: restartTooltipText.implicitWidth + Style.marginM * 2 * scaling
                  implicitHeight: restartTooltipText.implicitHeight + Style.marginM * 2 * scaling
                }

                MouseArea {
                  id: restartButtonArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    CompositorService.reboot()
                  }
                  // Tooltip handled via inline rectangle visibility
                }
              }

              // Suspend
              Rectangle {
                Layout.preferredWidth: iconSuspend.implicitWidth + Style.marginXL * scaling
                Layout.preferredHeight: Layout.preferredWidth
                radius: width * 0.5
                color: suspendButtonArea.containsMouse ? Color.mSecondary : Qt.alpha(Color.mSecondary, 0.2)
                border.color: Color.mSecondary
                border.width: Math.max(1, Style.borderM * scaling)

                NIcon {
                  id: iconSuspend
                  anchors.centerIn: parent
                  icon: "suspend"
                  font.pointSize: Style.fontSizeXXXL * scaling
                  color: suspendButtonArea.containsMouse ? Color.mOnSecondary : Color.mSecondary
                }

                // Tooltip
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.top
                  anchors.bottomMargin: 12 * scaling
                  radius: Style.radiusM * scaling
                  color: Color.mSurface
                  border.color: Color.mOutline
                  border.width: Math.max(1, Style.borderS * scaling)
                  visible: suspendButtonArea.containsMouse
                  z: 1
                  NText {
                    id: suspendTooltipText
                    anchors.margins: Style.marginM * scaling
                    anchors.fill: parent
                    text: "Suspend the system."
                    font.pointSize: Style.fontSizeM * scaling
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                  }
                  implicitWidth: suspendTooltipText.implicitWidth + Style.marginM * 2 * scaling
                  implicitHeight: suspendTooltipText.implicitHeight + Style.marginM * 2 * scaling
                }

                MouseArea {
                  id: suspendButtonArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    CompositorService.suspend()
                  }
                  // Tooltip handled via inline rectangle visibility
                }
              }
            }
          }

          Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
              timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
              dateText.text = Qt.formatDateTime(new Date(), "dddd, MMMM d")
            }
          }
        }
      }
    }
  }
}
