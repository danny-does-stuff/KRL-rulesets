ruleset manage_fleet {
	meta {
		name "manage_fleet"
		description << Fleet managing ruleset for the fleet pico >>
		author "Danny Harding"
		logging on
		use module Subscriptions
		shares __testing, fleetTrips, lastFiveReports
	}

	global {
		__testing = { 
			"queries": [ { "name": "__testing" }, { "name": "fleetTrips" }, { "name": "lastFiveReports" } ],
			"events": [
				{ 
					"domain": "car",
					"type": "new_vehicle",
					"attrs": [ "vehicleID" ]
				},
				{
					"domain": "create",
					"type": "car_pico",
					"attrs": [ "vehicleID" ]
				},
				{
					"domain": "car",
					"type": "unneeded_vehicle",
					"attrs": [ "vehicleID" ]
				},
				{
					"domain": "request",
					"type": "trip_reports"
				}
			]
		}

		subscriptionNameFromID = function(vehicleID) {
			"car" + vehicleID
		}

		subscriptionName = function(vehicleID) {
			subscriptionNameSpace + ":" + subscriptionNameFromID(vehicleID)
		}

		vehicles = function() {
			Subscriptions:getSubscriptions().filter(function(subscription) {
				subscription{"attributes"}{"subscriber_role"} == "vehicle"
			})
		}

		getTrips = function(vehicleECI) {
			result = http:get("http://localhost:8080/sky/cloud/" + vehicleECI + "/trip_store/trips");
			result{ "content" }.decode()
		}

		getJSON = function(len, vehicleECI) {
			vehicleTrips = {
				"vehicles": len,
				"responding": len,
				"trips": getTrips(vehicleECI)
			}
		}

		fleetTrips = function() {
			vehicles = ent:vehicles;
			vehicles.map(function(vehicle, vehicleID) {
				getJSON(vehicles.keys().length(), vehicle.eci)
			})
		}

		lastFiveReports = function() {
			length = ent:reports.keys().length();
			(length > 5) => ent:reports.values().slice(length - 5, length - 1) | ent:reports.values()
		}

		subscriptionNameSpace = "fleet-car"
	}

	rule create_vehicle {
		select when car new_vehicle
		pre {
			vehicleID = event:attr("vehicleID").defaultsTo(0)
		}
		always {
			raise create event "car_pico"
				attributes { "vehicleID": vehicleID }
		}
	}

	rule create_pico {
		select when create car_pico
		pre {
			vehicleID = event:attr("vehicleID")
			exists = ent:vehicles >< vehicleID
			newPicoName = "car numero " + vehicleID
		}
		if exists then
			send_directive("vehicle ready")
				with vehicleID = vehicleID
		fired {
		} else {
			raise pico event "new_child_request"
				attributes { "dname": newPicoName, "color": "#FF69B4", "vehicleID": vehicleID}
		}
	}

	rule pico_child_initialized {
		select when pico child_initialized
		pre {
			vehicle = event:attr("new_child")
			vehicleID = event:attr("rs_attrs"){"vehicleID"}
			vehicleECI = vehicle.eci
		}

			event:send( { "eci": vehicle.eci, "eid": "install-ruleset",
					"domain": "pico", "type": "new_ruleset",
					"attrs": { "rid": "Subscriptions", "vehicleID": vehicleID } } )
			event:send( { "eci": vehicle.eci, "eid": "install-ruleset",
					"domain": "pico", "type": "new_ruleset",
					"attrs": { "rid": "trip_store", "vehicleID": vehicleID } } )
			event:send( { "eci": vehicle.eci, "eid": "install-ruleset",
					"domain": "pico", "type": "new_ruleset",
					"attrs": { "rid": "track_mo_trips", "vehicleID": vehicleID } } )

		fired {
			ent:vehicles := ent:vehicles.defaultsTo({});
			ent:vehicles{ vehicleID } := vehicle;
			raise create event "car_subscription"
				attributes { "vehicle": vehicle, "vehicleID": vehicleID }
		}
	}

	rule create_subscription {
		select when create car_subscription
		pre {
			vehicle = event:attr("vehicle")
			vehicleID = event:attr("vehicleID")
			eci = meta:eci
		}
			event:send(
			{ "eci": eci, "eid": "subscription",
				"domain": "wrangler", "type": "subscription",
				"attrs": { 
					"name": subscriptionNameFromID(vehicleID),
					"name_space": subscriptionNameSpace,
					"my_role": "fleet",
					"subscriber_role": "vehicle",
					"channel_type": "subscription",
					"subscriber_eci": vehicle.eci
				}
			}
		)
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
		pre {
			vehicleID = event:attr("vehicleID")
			vehicle = ent:vehicles{ vehicleID }
			exists = ent:vehicles >< (vehicleID)
		}
		if exists then
			send_directive("removing vehicle")
				with vehicleID = vehicleID
		fired {
			raise wrangler event "subscription_cancellation"
				with subscription_name = subscriptionName(vehicleID);
			raise pico event "delete_child_request"
				attributes vehicle;
			ent:vehicles{ vehicleID } := null
		}
	}

	rule request_reports {
		select when request trip_reports
		foreach ent:vehicles setting (vehicle, vehicleID)
			pre {
				reports = ent:reports.defaultsTo({})
				reportID = reports.length()
			}
			event:send({
				"eci": vehicle.eci,
				"eid": "make mah report",
				"domain": "car",
				"type": "make_report",
				"attrs": {
					"reportID": reportID,
					"uniqueID": vehicleID,
					"requestorECI": meta:eci
				}
			})
	}

	rule report_created {
		select when car report_created
		pre {
			reportID = event:attr("reportID")
			vehicleID = event:attr("uniqueID")
			report = event:attr("report")
		}

		always {
			ent:reports := ent:reports.defaultsTo({});
			ent:reports{[reportID]} := ent:reports{[reportID]}.defaultsTo({});
			ent:reports{[reportID, "responding"]} := ent:reports{[reportID, "responding"]}.defaultsTo(0);
			ent:reports{[reportID, "responding"]} := ent:reports{[reportID, "responding"]} + 1;
			ent:reports{[reportID, "vehicles"]} := ent:vehicles.keys().length();
			ent:reports{[reportID, vehicleID]} := report
		}
	}
}