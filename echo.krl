ruleset echo {
	meta {
		name "echo"
		description << An echo ruleset >>
		author "Danny Harding"
		logging on
		shares __testing
	}

	global {

		__testing = { 
			"queries": [ { "name": "__testing" } ],
			"events": [ { "domain": "echo", "type": "hello" }, { "domain": "echo", "type": "message", "attrs": [ "input" ] } ]
		}
	}

	rule hello_world {
		select when echo hello
		send_directive("say") with
			something = "Hello World"
	}

	rule hello_world {
		select when echo message
		pre {
			message = event:attr("input").defaultsTo("Y U NO GIVE MESSAGE")
		}
		send_directive("say") with
			something = message
	}
}