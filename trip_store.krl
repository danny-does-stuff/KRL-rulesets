ruleset trip_store {
	meta {
		name "trip_store"
		description << The trip store ruleset >>
		author "Danny Harding"
		logging on
		provides trips, long_trips, short_trips
		shares __testing, trips, long_trips, short_trips
	}

	global {

		__testing = { 
			"queries": [ { "name": "__testing" }, { "name": "trips" }, { "name": "long_trips" }, { "name": "short_trips" } ],
			"events": [ { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
						{ "domain": "explicit", "type": "found_long_trip", "attrs": [ "mileage" ] },
						{ "domain": "car", "type": "trip_reset" } ]
		}

		trips = function() {
			ent:trips.defaultsTo({})
		}

		long_trips = function() {
			ent:long_trips
		}

		short_trips = function() {
			ent:trips.filter(function(key, value) {
				not ent:long_trips >< key
			})
		}

		empty_trips = {}
	}

	rule collect_trips {
		select when explicit trip_processed
		pre {
			mileage = event:attr("mileage")
			time = event:attr("timestamp")
		}
		always {
			ent:trips{ [time] } := {"mileage": mileage, "timestamp": time}
		}
	}

	rule collect_long_trips {
		select when explicit found_long_trip
		pre {
			mileage = event:attr("mileage")
			time = event:attr("timestamp")
		}
		always {
			ent:long_trips{ [time] } := {"mileage": mileage, "timestamp": time}
		}

	}

	rule clear_trips {
		select when car trip_reset
		always {
			ent:trips := empty_trips;
			ent:long_trips := empty_trips
		}
	}

	rule make_report {
		select when car make_report
		pre {
			requestorECI = event:attr("requestorECI")
			reportID = event:attr("reportID")
			uniqueID = event:attr("uniqueID")
			myTrips = trips()
		}
		event:send({
			"eci": requestorECI,
			"eid": "make mah report",
			"domain": "car",
			"type": "report_created",
			"attrs": {
				"reportID": reportID,
				"uniqueID": uniqueID,
				"report": myTrips
			}
		})
	}
}