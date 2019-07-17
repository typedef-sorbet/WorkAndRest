function timeFormatting(seconds) {
	var numHrs = Math.floor(Math.floor(seconds / 60) / 60)
        var numMins = Math.floor(seconds / 60) % 60
        var numSecs = seconds % 60

        var hrsText = "" + numHrs > 0 ? (numHrs > 9 ? numHrs : "0" + numHrs) + ":" : ""
        var minsText = ("" + numMins > 9 ? numMins : "0" + numMins) + ":"
        var secsText = "" + numSecs > 9 ? numSecs : "0" + numSecs

	return hrsText + minsText + secsText
}
