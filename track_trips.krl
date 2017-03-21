ruleset track_trips {
	meta {
		name "track_trips"
		description << A track trips ruleset >>
		author "Danny Harding"
		logging on
		shares __testing
	}

	global {

		__testing = { 
			"queries": [ { "name": "__testing" } ],
			"events": [ { "domain": "echo", "type": "message", "attrs": [ "input" ] } ]
		}
	}

	rule process_trip {
		select when echo message
		pre {
			mileage = event:attr("mileage")
		}
		send_directive("trip") with
			trip_length = mileage
	}
}