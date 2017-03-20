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
      "events": [ { "domain": "echo", "type": "hello" }, { "domain": "hello", "type": "name", "attrs": [ "name" ] }, { "domain": "hello", "type" : "clear" } ]
    }

    clear_name = { "_0": { "name": { "first": "GlaDOS", "last": "" } } }
  }
  
  rule hello_world {
    select when echo hello
    pre{
      name = event:attr("name").defaultsTo(ent:name, "use stored name")
    }
    send_directive("say") with
      something = "Hello " + name
  }

  rule store_name {
    select when hello name
    pre{
      name = event:attr("name").klog("our passed in name: ")
    }
    send_directive("store_name") with
      name = name
    always{
      ent:name := name
    }
  }

  rule clear_names {
    select when hello clear
    always {
      ent:name := clear_name
    }
  }
  
}