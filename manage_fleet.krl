ruleset manage_fleet {
	meta {
		name "manage_fleet"
		description << Fleet managing ruleset for the fleet pico >>
		author "Danny Harding"
		logging on
    use module Subscriptions
		shares __testing
	}

	global {
		__testing = { 
			"queries": [ { "name": "__testing" } ],
			"events": [
				{ "domain": "car", "type": "new_vehicle", "attrs": [ "subscriptionName" ] },
				{ "domain": "create", "type": "car_pico" }
			]
		}

    vehicles = function() {
      ent:subscriptions
    }
	}

	rule create_vehicle {
		select when car new_vehicle
		pre {
			subscriptionName = event:attr("subscriptionName").defaultsTo("Fleet-Car subscription")
		}
		always {
			raise create event "car_pico"
        attributes { "subscriptionName": subscriptionName }
		}
	}

	rule create_pico {
		select when create car_pico
		pre {
      vehicleID = ent:numCars
			newPicoName = "car" + ent:numCars
      subscriptionName = event:attr("subscriptionName")
		}
		always {
			ent:numCars := ent:numCars + 1;
			raise pico event "new_child_request"
				attributes { "dname": newPicoName, "color": "#FF69B4", "vehicleID": vehicleID, "subscriptionName": subscriptionName }
		}
	}

	rule pico_child_initialized {
    select when pico child_initialized
    pre {
      vehicle = event:attr("new_child")
      vehicleID = event:attr("rs_attrs"){"vehicleID"}
      vehicleECI = vehicle.eci
      subscriptionName = event:att("rs_attrs"){"subscriptionName"}
      eci = meta:eci
      subscriptionName = event:attr("subscriptionName")
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
      event:send(
        { "eci": eci, "eid": "subscription",
          "domain": "wrangler", "type": "subscription",
          "attrs": { 
            "name": subscriptionName,
            "name_space": "fleet-car",
            "my_role": "fleet",
            "subscriber_role": "vehicle",
            "channel_type": "subscription",
            "subscriber_eci": vehicleECI
          }
        }
      )
    fired {
      ent:vehicles := ent:vehicles.defaultsTo({});
      ent:vehicles{[vehicleID]} := vehicle
    }
  }
}