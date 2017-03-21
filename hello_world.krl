ruleset hello_world {
  meta {
    name "Hello World"
    description <<
A first ruleset for the Quickstart
>>
    author "Phil Windley"
    logging on
    shares hello, __testing
  }
  
  global {
    hello = function(obj) {
      msg = "Hello " + obj;
      msg
    }

    __testing = { "queries": [ { "name": "hello", "args": [ "obj" ] },
        { "name": "__testing" } ],
      "events": [ { "domain": "echo", "type": "hello", "attrs": [ "id" ] }, { "domain": "hello", "type": "name", "attrs": [ "id", "first_name", "last_name" ] }, { "domain": "hello", "type" : "clear" } ]
    }

    clear_name = { "_0": { "name": { "first": "GlaDOS", "last": "" } } }
  }

  name = function(id) {
    all_users = users();
    nameObj = id => all_users{[id,"name"]}
                  | { "first": "HAL", "last": "9000" };
    first = nameObj{"first"};
    last = nameObj{"last"};
    first + " " + last
  }
   
  users = function() {
    ent:name
  }
  
  rule hello_world {
    select when echo hello
    pre{
      id = event:attr("id").defaultsTo("_0")
      name = name(id)
      visits = ent:name{[id,"visits"]}
    }
    send_directive("say") with
      something = "Hello " + name
    fired {
      ent:name{[id,"visits"]} := visits + 1
    }
  }

  rule store_name {
    select when hello name
    pre{
      passed_id = event:attr("id").klog("our passed in id: ")
      passed_first_name = event:attr("first_name").klog("our passed in first_name: ")
      passed_last_name = event:attr("last_name").klog("our passed in last_name: ")
    }
    send_directive("store_name") with
      id = passed_id
      first_name = passed_first_name
      last_name = passed_last_name
    always{
      ent:name := ent:name.defaultsTo(clear_name,"initialization was needed");
      ent:name{[passed_id,"name","first"]} := passed_first_name;
      ent:name{[passed_id,"name","last"]} := passed_last_name
    }
  }

  rule clear_names {
    select when hello clear
    always {
      ent:name := clear_name
    }
  }
  
}