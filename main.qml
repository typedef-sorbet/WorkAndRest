import QtQuick 2.11
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.11
import "Icon.js" as MdiFont
import "TimeFormatting.js" as TimeFormatting

// Main window of the application.
ApplicationWindow {
    id: window

    // Formatting
    visible: true
    width: 400; minimumWidth: 400; maximumWidth: 400
    height: 300; minimumHeight: 300; maximumHeight: 300
    title: qsTr("Work Timer")
    color: "lightgrey"

    // Rectangle that highlights the active timer in grey
    Rectangle {
        id: highlighter

        // Formatting
        width: parent.width
        height: work_timer.height + 15
        anchors.top: work_timer.top
        color: "grey"

        // function to change states (i.e. change positions)
        function swapPlaces() {
            if(state == "WorkingPos")
            {
                state = "RestingPos"
            }
            else
            {
                state = "WorkingPos"
            }
        }

        // denotes the two states of the highlighter: hovering over the rest timer, and hovering over the work timer
        states: [
            State {                     // RestingPos anchors the top of the rectangle to the top of the rest timer text box
                name: "RestingPos"
                AnchorChanges {
                    target: highlighter
                    anchors.top: rest_timer.top
                }
            },
            State {                     // WorkingPos anchors the top of the rectangle to the top of the window (effectively the same as the top of the work timer)
                name: "WorkingPos"
                AnchorChanges {
                    target: highlighter
                    anchors.top: window.top
                }
            }
        ]

        // Denotes the animations that occur between state changes (mainly for easing the rectangle between the two positions)
        transitions: [
            Transition {
                AnchorAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        ]

        // Default to hovering over the work timer
        state: "WorkingPos"
    }

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

        // when accepted, change work_timer's and highlighter's state, start the clock tick, and close the dialog
        onAccepted: {
            work_timer.state = "Working"
            highlighter.state = "WorkingPos"
            clock_tick.start()
            close()
        }
    }

    // 1 second timer to keep track of the passage of time
    Timer {
        id: clock_tick

        // 1 sec interval
        interval: 1000

        // default to not running; repeat the timer
        running: false
        repeat: true

        // When the timer ticks...
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
                // if we've run out of rest time...
                if(work_timer.restSeconds <= 0)
                {
                    // stop the clock tick for the time being
                    clock_tick.stop()
                    // pop up a dialog that says that the user has run out of rest time
                    time_up_dialog.open()
                }
                else
                {
                    // decrement the rest seconds by one
                    work_timer.restSeconds--

                    // send out a debug message
                    console.log("Clock ticked while resting! Accrued seconds left: " + work_timer.restSeconds)

                    // update the rest timer text
                    rest_timer.text = TimeFormatting.timeFormatting(work_timer.restSeconds)
                }
            }
        }
    }

    // Label for the work timer
    Text {
        id: work_label

        // Formatting
        font.pointSize: 24
        text: "Work Time"
        anchors.margins: 15
        anchors.leftMargin: 30
        anchors.left: parent.left
        anchors.verticalCenter: work_timer.verticalCenter
    }

    // The work timer
    // Shows the amount of time the user has spent working.
    Text {
        id: work_timer

        // Formatting
        font.pointSize: 32
        text: "00:00"
        anchors.margins: 15
        anchors.rightMargin: 30
        anchors.right: parent.right

        // store the number of seconds worked (for display purposes),
        // the number of seconds accrued while working (for rest-time calc. purposes),
        // and the number of seconds the user can rest (based on ratio and accruedSeconds) respectively
        property int totalSeconds
        property int accruedSeconds
        property int restSeconds

        // store the ratio that was selected by the user (set by ratio_selector_num and ratio_selector_denom)
        property double ratio: 1.0

        // States
        // Handles the overall state for both work_timer and rest_timer
        // This timer is effectively the "master" timer
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
            // ...and we're about to start working...
            if(state == "Working")
            {
                // ...backfill accruedSeconds with the appropriate amount of seconds it would take to accrue the remaining restSeconds
                accruedSeconds = Math.ceil(1 / ratio * restSeconds)
                // This here is the main reason why I differentiate between accruedSeconds and totalSeconds.
                // If I were to backfill totalSeconds using this logic, it could potentially desynch the timer text with the amount of time that has actually passed.
                // Doing it this way still creates some inaccuracy between the amount of time accrued to rest and the amount of time worked, but keep[s the information that is displayed
                // in check with the total amount of time that has passed.
                // I think, anyway.
            }
        }
    }

    // Label for the rest timer
    Text {
        id: rest_label

        // Formatting
        font.pointSize: 24
        text: "Rest Time"
        anchors.margins: 15
        anchors.leftMargin: 30
        anchors.verticalCenter: rest_timer.verticalCenter
        anchors.horizontalCenter: work_label.horizontalCenter
    }

    // The rest timer
    // No timer logic here, text updates handled by work_timer and clock_tick.
    Text {
        id: rest_timer

        // Formatting
        font.pointSize: 32
        text: "00:00"
        anchors.margins: 15
        anchors.rightMargin: 30
        anchors.right: parent.right
        anchors.top: work_timer.bottom

        // All the logic for accrued rest time happens in clock_tick. See above.
    }

    // ComboBox for selecting the desired ratio between work time and rest time.
    ComboBox {
        id: ratio_selector_num

        // default to 1
        currentIndex: 0

        // Formatting
        width: 75
        anchors.margins: 15
        anchors.topMargin: 30
        anchors.right: ratio_delimiter.left
        anchors.verticalCenter: ratio_delimiter.verticalCenter

        // Returns the integer contained within the current selection.
        function getSelectionAsInt()
        {
            return parseInt(ratio_list_num.get(ratio_selector_num.currentIndex).text)
        }

        // list of available ratios
        // TODO add a value field to each element se that we don't have to do string parsing
        model: ListModel {
            id: ratio_list_num
            ListElement { text: "1" }
            ListElement { text: "2" }
            ListElement { text: "3" }
            ListElement { text: "4" }
            ListElement { text: "5" }
            ListElement { text: "6" }
            ListElement { text: "7" }
            ListElement { text: "8" }
            ListElement { text: "9" }
            ListElement { text: "10" }
        }

        // If the ratio is changed...
        onCurrentIndexChanged: {
            // change the currently chosen ratio
            work_timer.ratio = ratio_selector_denom.getSelectionAsInt() / ratio_selector_num.getSelectionAsInt()

            // send out a debug message
            console.log("Ratio changed to " + work_timer.ratio)

            // update the rest_seconds to reflect the new ratio *immediately* (don't wait for the next clock tick)
            work_timer.restSeconds = Math.floor(work_timer.ratio * work_timer.accruedSeconds)
        }
    }

    // Text between the two ComboBoxes.
    Text {
        id: ratio_delimiter

        // Formatting
        text: ":"
        font.pointSize: 8
        anchors.topMargin: 35
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: rest_timer.bottom
    }

    // ComboBox for selecting the desired ratio between work time and rest time.
    ComboBox {
        id: ratio_selector_denom

        // default to 1
        currentIndex: 0

        // formatting
        width: 75
        anchors.margins: 15
        anchors.topMargin: 30
        anchors.left: ratio_delimiter.right
        anchors.verticalCenter: ratio_delimiter.verticalCenter

        // Returns the integer contained within the current selection.
        function getSelectionAsInt()
        {
            return parseInt(ratio_list_denom.get(ratio_selector_denom.currentIndex).text)
        }

        // list of available ratios
        // TODO add a value field to each element se that we don't have to do string parsing
        model: ListModel {
            id: ratio_list_denom
            ListElement { text: "1" }
            ListElement { text: "2" }
            ListElement { text: "3" }
            ListElement { text: "4" }
            ListElement { text: "5" }
            ListElement { text: "6" }
            ListElement { text: "7" }
            ListElement { text: "8" }
            ListElement { text: "9" }
            ListElement { text: "10" }
        }

        // If the ratio is changed...
        onCurrentIndexChanged: {
            // change the currently chosen ratio
            work_timer.ratio = ratio_selector_denom.getSelectionAsInt() / ratio_selector_num.getSelectionAsInt()

            // send out a debug message
            console.log("Ratio changed to " + work_timer.ratio)

            // update the rest_seconds to reflect the new ratio *immediately* (don't wait for the next clock tick)
            work_timer.restSeconds = Math.floor(work_timer.ratio * work_timer.accruedSeconds)
        }
    }

    // Label underneath the numerator ComboBox.
    Text {
        id: ratio_num_label

        // Formatting
        text: "Time working"
        font.pointSize: 8
        anchors.horizontalCenter: ratio_selector_num.horizontalCenter
        anchors.top: ratio_selector_num.bottom
    }

    // Label underneath the ratio delimiter label.
    Text {
        id: ratio_delimiter_label

        // Formatting
        text: "to"
        font.pointSize: 8
        anchors.horizontalCenter: ratio_delimiter.horizontalCenter
        anchors.verticalCenter: ratio_num_label.verticalCenter
    }

    // Label underneath the denominator ComboBox.
    Text {
        id: ratio_denom_label

        // Formatting
        text: "time resting"
        font.pointSize: 8
        anchors.horizontalCenter: ratio_selector_denom.horizontalCenter
        anchors.top: ratio_selector_denom.bottom
    }

    // Button to switch between Working and Resting
    RoundButton {
        id: switch_button

        // Formatting
        anchors.margins: 20
        x: parent.width / 2 - width - anchors.margins / 2
        anchors.bottom: parent.bottom
        height: 50; width: 50
        font.family: "Material Design Icons"
        font.pixelSize: 24
        text: MdiFont.Icon.cached   // Circular "repeat"-like symbol, similar to the retweet symbol
        opacity: 0.80

        // Toggle work_timer.state on press, and move the highlighter box
        onPressed: {
            if(work_timer.state == "Working")
            {
                work_timer.state = "Resting"
            }
            else
            {
                work_timer.state = "Working"
            }

            highlighter.swapPlaces()
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
