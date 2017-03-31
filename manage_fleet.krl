ruleset manage_fleet {
	meta {
		name "manage_fleet"
		description << Fleet managing ruleset for the fleet pico >>
		author "Danny Harding"
		logging on
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
	}

	rule create_vehicle {
		select when car new_vehicle
		pre {
			//subscriptionName = event:attr("subscriptionName").defaultsTo("Fleet-Car subscription")

			//attributes = {}
			//	.put(["name"], "New Car")
			//	.put(["owner"], "Owner Name?")
			//	.put(["Prototype_rids"], "b507780x54.prod, b507780x56.prod") //Installs rule sets b507780x54.prod and b507780x56.prod in the newly created Pico
		}
		always {
			raise create event "car_pico"
		}
	}

	rule create_pico {
		select when create car_pico
		pre {
			eci = meta:eci
			newPicoName = "car" + ent:numCars
		}
		always {
			ent:numCars := ent:numCars + 1;
			raise pico event "new_child_request"
				attributes { "dname": newPicoName, "color": "#FF69B4" }
		}

	}
}