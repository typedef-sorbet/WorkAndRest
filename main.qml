import QtQuick 2.11
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.11
import "Icon.js" as MdiFont
import "TimeFormatting.js" as TimeFormatting

ApplicationWindow {
    id: window

    visible: true
    width: 400
    height: 300
    title: qsTr("Work Timer")

    color: "lightgrey"

    Dialog {
        id: time_up_dialog
        modal: true
        visible: false
        width: 300; height: 200

        Text {
            id: text
            text: qsTr("Time up!")
            anchors.centerIn: parent
        }
    }

    Text {
        id: work_label
        font.pointSize: 24
        text: "Work Timer"

        anchors.margins: 15
        anchors.left: parent.left
        anchors.verticalCenter: work_timer.verticalCenter
    }

    Text {
        id: work_timer
        font.pointSize: 32
        text: "00:00"

        anchors.margins: 15
        anchors.right: parent.right

        property int totalSeconds
        property int accruedSeconds
        property int restSeconds

        property alias ratio: ratio_selector.chosen_ratio

        Timer {
            id: clock_tick

            interval: 1000
            running: false
            repeat: true

            onTriggered: {
                if(work_timer.state == "Working")
                {
                    work_timer.totalSeconds++
                    work_timer.accruedSeconds++
                    work_timer.restSeconds = Math.floor(work_timer.accruedSeconds * work_timer.ratio)

                    console.log("Clock ticked while working! Total seconds: " + work_timer.totalSeconds)

                    work_timer.text = TimeFormatting.timeFormatting(work_timer.totalSeconds)
                    rest_timer.text = TimeFormatting.timeFormatting(work_timer.restSeconds)
                }
                else
                {
                    work_timer.restSeconds--
                    console.log("Clock ticked while resting! Accrued seconds left: " + work_timer.restSeconds)

                    rest_timer.text = TimeFormatting.timeFormatting(work_timer.restSeconds)

                    if(work_timer.restSeconds <= 0)
                    {
                        console.log("Time up!")
                        work_timer.state = "Working"
                    }
                }
            }
        }

        states: [
            State {
                id: working_state
                name: "Working"
            },
            State {
                id: resting_state
                name: "Resting"
            }
        ]

        state: "Working"

        onStateChanged: {
            if(state == "Working")
            {
                // backfill accruedSeconds with the appropriate amount of seconds it would take to accrue the remaining restSeconds
                accruedSeconds = Math.ceil(1 / ratio * restSeconds)
            }
        }
    }

    Text {
        id: rest_label
        font.pointSize: 24
        text: "Rest Timer"

        anchors.margins: 15
        anchors.verticalCenter: rest_timer.verticalCenter
        anchors.horizontalCenter: work_label.horizontalCenter
    }

    Text {
        id: rest_timer
        font.pointSize: 32
        text: "00:00"

        anchors.margins: 15
        anchors.right: parent.right
        anchors.top: work_timer.bottom

    }

    Text {
        id: ratio_label
        font.pointSize: 16
        text: "Ratio (work to rest)"

        anchors.horizontalCenter: rest_label.horizontalCenter
        anchors.verticalCenter: ratio_selector.verticalCenter
    }

    ComboBox {
        id: ratio_selector
        currentIndex: 0
        width: 100

        anchors.margins: 15
        anchors.topMargin: 30

        anchors.top: rest_timer.bottom
        anchors.horizontalCenter: rest_timer.horizontalCenter

        property double chosen_ratio: 1

        model: ListModel {
            id: ratio_list
            ListElement { text: "1/1" }
            ListElement { text: "2/1" }
            ListElement { text: "3/1" }
            ListElement { text: "4/1" }
            ListElement { text: "5/1" }
            ListElement { text: "3/2" }
            ListElement { text: "4/3" }
            ListElement { text: "5/4" }
        }
        onCurrentIndexChanged: {
            console.log("Ratio changed to " + ratio_list.get(currentIndex).text)
            // Yes, I know this is *technically* dangerous. However, in this context, I don't see how this can be abused outside of the user creating their own list elements.
            // And even then, this command is only going to run on their machine. Whatever malicious things they may be able to do here will be self-inflicted.
            chosen_ratio = eval("1 / (" + ratio_list.get(currentIndex).text + ")")
        }
    }

    RoundButton {
        id: switch_button

        anchors.margins: 20
        anchors.right: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: 50; width: 50

        font.family: "Material Design Icons"
        font.pixelSize: 24

        onPressed: {
            if(work_timer.state == "Working")
            {
                work_timer.state = "Resting"
            }
            else
            {
                work_timer.state = "Working"
            }

        }
        text: MdiFont.Icon.cached
        opacity: 0.80

    }

    RoundButton {
        anchors.margins: 20
        anchors.left: switch_button.right
        anchors.bottom: parent.bottom
        id: pause_button
        height: 50; width: 50

        font.family: "Material Design Icons"
        font.pixelSize: 24
        opacity: 0.80

        onPressed: {
            if(state == "Playing")
            {
                state = "Paused"
                console.log("User Paused")
                clock_tick.stop()
            }
            else
            {
                state = "Playing"
                console.log("User Unpaused")
                clock_tick.start()
            }
        }
        text: "Pause"

        states: [
            State {
                id: playing_state
                name: "Playing"
                PropertyChanges {
                    target: pause_button
                    text: MdiFont.Icon.pause
                }
            },
            State {
                id: paused_state
                name: "Paused"
                PropertyChanges {
                    target: pause_button
                    text: MdiFont.Icon.play
                }
            }
        ]

        state: "Paused"
    }

}
