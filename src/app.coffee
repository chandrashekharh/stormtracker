config = require('../package').config
GLOBAL.config = config

auth = require("http/auth")

require("passport").use require("http/auth").BasicStrategy

StormTracker = require "stormtracker"

tracker = new StormTracker
tracker.run()
