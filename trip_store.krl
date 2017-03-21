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
			"queries": [ { "name": "__testing" } ],
			"events": [ { "domain": "explicit", "type": "trip_processed", "attrs": [ "mileage" ] },
						{ "domain": "explicit", "type": "found_long_trip", "attrs": [ "mileage" ] } ]
		}

		trips = function() {
			ent:trips
		}

		long_trips = function() {
			ent:long_trips
		}

		short_trips = function() {
			
		}

		empty_trips = {}

		tripID = 0
	}

	rule collect_trips {
		select when explicit trip_processed
		pre {
			mileage = event:attr("mileage")
			time = event:attr("timestamp")
		}
		always {
			ent:trips{[ tripID ]} := {"mileage": mileage, "timestamp": time};
			tripID = tripID + 1
		}
	}

	rule collect_long_trips {
		select when explicit found_long_trip
		pre {
			mileage = event:attr("mileage")
			time = event:attr("timestamp")
		}
		always {
			ent:long_trips{[ tripID ]} := {"mileage": mileage, "timestamp": time};
			tripID = tripID + 1
		}

	}

	rule clear_trips {
		select when car trip_reset
		always {
			ent:trips := empty_trips;
			ent:long_trips := empty_trips
		}
	}
}