config = require('../package').config
GLOBAL.config = config

require("passport").use require("./auth/auth").BasicStrategy

StormAgent = require "stormagent"

tracker = new StormAgent(config)
tracker.on "ready", ->
	CertificateFactory = require("http/certs").CertificateFactory
	new CertificateFactory().init()
	@include require("./src/http/agents")
	@include require("./src/http/certs")

tracker.on "active", (storm)->
	@log "firing up stormbolt"


tracker.run()
