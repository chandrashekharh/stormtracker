StormAgent = require "stormagent"
AgentsRegistry = require("http/agents").AgentsRegistry
AgentsManager = require("http/agents").AgentsManager
CertificateRegistry = require("security/certificate").CertificateRegistry

class StormTracker extends StormAgent
	constructor : () ->
		super
		@import module

		@log "StormTracker constructor called "+global.config.datadir
		@certsdb  = new CertificateRegistry "#{global.config.datadir}/certs.db"
		@agentsdb = new AgentsRegistry "#{global.config.datadir}/agents.db"

		CertificateFactory = require("http/certs").CertificateFactory
		@CF = new CertificateFactory(@certsdb)
		@CF.init()

		@AM = new AgentsManager(@agentsdb,@CF.CM)

	run : (config) ->
		super config
		console.log "Inside run....."

module.exports = StormTracker
