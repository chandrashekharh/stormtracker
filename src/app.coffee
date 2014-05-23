config = require('../package').config
GLOBAL.config = config

StormTracker = require "./stormtracker"

new StormTracker().run()
