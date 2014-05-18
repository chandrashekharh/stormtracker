config = require('../package').config
GLOBAL.config = config

auth = require("http/auth")

require("passport").use require("http/auth").BasicStrategy

StormAgent = require "stormagent"

tracker = new StormAgent(config)
tracker.on "ready", ->
	CertificateFactory = require("http/certs").CertificateFactory
	new CertificateFactory().init()
	@include require("http/agents")
	@include require("http/certs")

tracker.on "active", (storm)->
	@log "firing up stormbolt"

tracker.run()
