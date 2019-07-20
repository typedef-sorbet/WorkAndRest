// Takes an amount of seconds and formats it as an "hh:mm:ss" formatted string
// (or "mm:ss" if the specified amt of time is less than an hour)
// Is there an easier/faster way to do this? Yeah, probably.
function timeFormatting(seconds) {
	var numHrs = Math.floor(Math.floor(seconds / 60) / 60)
    var numMins = Math.floor(seconds / 60) % 60
    var numSecs = seconds % 60

    // Can you tell I like ternaries?

    var hrsText = "" + numHrs > 0 ? (numHrs > 9 ? numHrs : "0" + numHrs) + ":" : ""     // if our amount of time has exceeded one hour, let this string be the number of hours passed (formatted as "hh") with a colon afterwards. Otherwise, let it be an empty string.
    var minsText = ("" + numMins > 9 ? numMins : "0" + numMins) + ":"                   // format the number of minutes as "mm" with a colon at the end
    var secsText = "" + numSecs > 9 ? numSecs : "0" + numSecs                           // format the number of seconds as "ss"

	return hrsText + minsText + secsText
}
