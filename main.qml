import QtQuick 2.11
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.11
import "Icon.js" as MdiFont
import "TimeFormatting.js" as TimeFormatting

ApplicationWindow {
    id: window

    // Formatting
    visible: true
    width: 400
    height: 300
    title: qsTr("Work Timer")

    color: "lightgrey"

    // time_up_dialog: Dialog that appears when the rest timer has depleted
    Dialog {
        id: time_up_dialog

        // Formatting
        modal: true
        focus: true
        width: 200; height: 150
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2
        title: qsTr("Rest Time Over")

        // Only have an OK button
        standardButtons: Dialog.Ok

        // dialog has a tet field that says "Time's up"
        contentItem: Text {
            id: text
            text: qsTr("Time up!")
            anchors.centerIn: parent
        }

        // when accepted, change work_timer's state, start the clock tick, and close the dialog
        onAccepted: {
            work_timer.state = "Working"
            clock_tick.start()
            close()
        }
    }

    // Label for the work timer
    Text {
        id: work_label
        font.pointSize: 24
        text: "Work Timer"

        anchors.margins: 15
        anchors.left: parent.left
        anchors.verticalCenter: work_timer.verticalCenter
    }

    // The work timer
    // Shows the amount of time the user has spent working.
    Text {
        id: work_timer
        font.pointSize: 32
        text: "00:00"

        anchors.margins: 15
        anchors.right: parent.right

        // store the number of seconds worked (for display purposes),
        // the number of seconds accrued while working (for rest-time calc. purposes),
        // and the number of seconds the user can rest (based on ratio and accruedSeconds) respectively
        property int totalSeconds
        property int accruedSeconds
        property int restSeconds

        // aliased property grabs the ratio selected by the user
        property alias ratio: ratio_selector.chosen_ratio

        // 1 second timer to keep track of the passage of time
        // TODO extract this; it doesn't need to belong to work_timer.
        Timer {
            id: clock_tick

            // 1 sec interval
            interval: 1000

            // default to not running; repeat the timer
            running: false
            repeat: true

            // Once the timer ticks...
            onTriggered: {
                // If we're in the working state...
                if(work_timer.state == "Working")
                {
                    // Add one to both totalSeconds and accruedSeconds
                    work_timer.totalSeconds++
                    work_timer.accruedSeconds++

                    // Calculate the number of restSeconds allotted based on the current ratio and the accrued seconds
                    work_timer.restSeconds = Math.floor(work_timer.accruedSeconds * work_timer.ratio)

                    // send out a debug message
                    console.log("Clock ticked while working! Total seconds: " + work_timer.totalSeconds)

                    // update the text on both the timers
                    work_timer.text = TimeFormatting.timeFormatting(work_timer.totalSeconds)
                    rest_timer.text = TimeFormatting.timeFormatting(work_timer.restSeconds)
                }
                else    // Otherwise...
                {
                    // decrement the rest seconds by one
                    work_timer.restSeconds--

                    // send out a debug message
                    console.log("Clock ticked while resting! Accrued seconds left: " + work_timer.restSeconds)

                    // update the rest timer text
                    rest_timer.text = TimeFormatting.timeFormatting(work_timer.restSeconds)

                    // if we've run out of rest time...
                    if(work_timer.restSeconds <= 0)
                    {
                        // stop the clock tick for the time being
                        clock_tick.stop();
                        // pop up a dialog that says that the user has run out of rest time
                        time_up_dialog.open();
                    }
                }
            }
        }

        // States
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

        // default to the Working state
        state: "Working"

        // If we've changed states...
        onStateChanged: {
            // ...and we're working...
            if(state == "Working")
            {
                // ...backfill accruedSeconds with the appropriate amount of seconds it would take to accrue the remaining restSeconds
                accruedSeconds = Math.ceil(1 / ratio * restSeconds)
                // This here is the main reason why I differentiate between accruedSeconds and totalSeconds.
                // If I were to backfill totalSeconds using this logic, it could potentially desynch the timer text with the amount of time that has actually passed.
                // Doing it this way still creates some inaccuracy between the amount of time accrued to rest and the amount of time worked, but keep[s the information that is displayed
                // in check with the total amount of time that has passed.
                // I think, anyway. Maybe this is my crackhead brain doing some weird somersaults or something. :/
            }
        }
    }

    // Label for the rest timer
    Text {
        id: rest_label
        font.pointSize: 24
        text: "Rest Timer"

        anchors.margins: 15
        anchors.verticalCenter: rest_timer.verticalCenter
        anchors.horizontalCenter: work_label.horizontalCenter
    }

    // The rest timer
    Text {
        id: rest_timer
        font.pointSize: 32
        text: "00:00"

        anchors.margins: 15
        anchors.right: parent.right
        anchors.top: work_timer.bottom

        // All the logic for accrued rest time happens in work_timer. See above.
    }

    // Label for the work ratio ComboBox.
    Text {
        id: ratio_label
        font.pointSize: 16
        text: "Ratio (work to rest)"

        anchors.horizontalCenter: rest_label.horizontalCenter
        anchors.verticalCenter: ratio_selector.verticalCenter
    }

    // ComboBox for selecting the desired ratio between work time and rest time.
    ComboBox {
        id: ratio_selector

        // default to 1/1
        currentIndex: 0

        // formatting
        width: 100
        anchors.margins: 15
        anchors.topMargin: 30
        anchors.top: rest_timer.bottom
        anchors.horizontalCenter: rest_timer.horizontalCenter

        // store chosen ratio as a double
        property double chosen_ratio: 1

        // list of available ratios
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

        // If the ratio is changed...
        onCurrentIndexChanged: {
            // send out a debug message
            console.log("Ratio changed to " + ratio_list.get(currentIndex).text)

            // change the currently chosen ratio
            chosen_ratio = eval("1 / (" + ratio_list.get(currentIndex).text + ")")

            // Yes, I know that is *technically* dangerous. However, in this context, I don't see how this can be abused outside of the user creating their own list elements.
            // And even then, this command is only going to run on their machine. Whatever malicious things they may be able to do here will be self-inflicted.

            // update the rest_seconds to reflect the new ratio *immediately* (don't wait for the next clock tick)
            work_timer.restSeconds = Math.floor(chosen_ratio * work_timer.accruedSeconds)
        }
    }

    // Button to switch between Working and Resting
    RoundButton {
        id: switch_button

        // Formatting
        anchors.margins: 20
        anchors.right: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: 50; width: 50
        font.family: "Material Design Icons"
        font.pixelSize: 24
        text: MdiFont.Icon.cached   // Circular "repeat"-like symbol, similar to the retweet symbol
        opacity: 0.80

        // Toggle work_timer.state on press
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
    }

    // Button to pause and unpause the timer
    RoundButton {
        id: pause_button

        // Formatting
        anchors.margins: 20
        anchors.left: switch_button.right
        anchors.bottom: parent.bottom
        height: 50; width: 50
        font.family: "Material Design Icons"
        font.pixelSize: 24
        opacity: 0.80

        // When pressed...
        onPressed: {
            if(state == "Playing")  // If we're currently unpaused...
            {
                state = "Paused"                // switch to the paused state
                console.log("User Paused")      // send out a debug message
                clock_tick.stop()               // and stop the clock tick timer
            }
            else                    // Otherwise...
            {
                state = "Playing"               // switch to the unpaused state
                console.log("User Unpaused")    // send out a debug message
                clock_tick.start()              // and start the clock tick timer
            }
        }

        // States
        states: [
            State {
                id: playing_state
                name: "Playing"
                PropertyChanges {
                    target: pause_button        // target this
                    text: MdiFont.Icon.pause    // change text to Pause symbol
                }
            },
            State {
                id: paused_state
                name: "Paused"
                PropertyChanges {
                    target: pause_button        // target this
                    text: MdiFont.Icon.play     // change text to Play symbol
                }
            }
        ]

        // default to Paused on startup
        state: "Paused"
    }

}
