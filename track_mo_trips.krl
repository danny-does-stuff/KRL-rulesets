ruleset track_mo_trips {
	meta {
		name "track_mo_trips"
		description << ANOTHER track trips ruleset >>
		author "Danny Harding"
		logging on
		shares __testing
	}

	global {

		__testing = { 
			"queries": [ { "name": "__testing" } ],
			"events": [ { "domain": "car", "type": "new_trip", "attrs": [ "mileage" ] } ]
		}

		long_trip = 100
	}

	rule process_trip {
		select when car new_trip
		pre {
			allAttributes = event:attrs()
		}
		always {
			raise explicit event "trip_processed"
				attributes allAttributes
		}
	}

	rule find_long_trips {
		select when explicit trip_processed
		pre {
			mileage = event:attr("mileage").as("Number")
		}
		if mileage > long_trip then
			send_directive("is_long")
		fired {
			raise explicit event "found_long_trip"
		}
	}
}