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
				{ "domain": "car", "type": "new_vehicle", "attrs": [ "vehicleID" ] },
				{ "domain": "create", "type": "car_pico" }
			]
		}

    subscriptionNameFromID = function(vehicleID) {
      "car" + vehicleID + " subscription"
    }

    vehicles = function() {
      ent:vehicles
    }
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
			newPicoName = "car" + vehicleID
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
      ent:vehicles{[vehicleID]} := vehicle;
      raise create event "car_subscription"
        attributes { "vehicle": vehicle, "vehicleID": vehicleID }
    }
  }

  rule create_subscription {
    select when create car_subscription
    pre {
      vehicle = event:attr("vehicle").klog("vehicle")
      vehicleID = event:attr("vehicleID").klog("vehilce ID")
      eci = meta:eci
    }
      event:send(
        { "eci": eci, "eid": "subscription",
          "domain": "wrangler", "type": "subscription",
          "attrs": { 
            "name": subscriptionNameFromID(vehicleID),
            "name_space": "fleet-car",
            "my_role": "fleet",
            "subscriber_role": "vehicle",
            "channel_type": "subscription",
            "subscriber_eci": vehicle.eci
          }
        }
      )
  }
}