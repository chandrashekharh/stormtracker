StormAgent = require 'stormagent'

class StormTracker extends StormAgent
	constructor : () ->
		super
		@import module
		AgentsRegistry = require("http/agents").AgentsRegistry
		AgentsManager = require("http/agents").AgentsManager
		CertificateRegistry = require("security/certificate").CertificateRegistry
		auth = require("http/auth")
		require("passport").use require("http/auth").BasicStrategy
		@log "StormTracker constructor called "+global.config.datadir
		@certsdb  = new CertificateRegistry "#{global.config.datadir}/certs.db"
		@agentsdb = new AgentsRegistry "#{global.config.datadir}/agents.db"
		CertificateFactory = require("http/certs").CertificateFactory
		@CF = new CertificateFactory(@certsdb)
		@CF.init()
		@AM = new AgentsManager(@agentsdb,@CF.CM)
		require("passport").use require("http/auth").BasicStrategy
		global.agentsDB=@agentsdb.db
	run : (config) ->
		super config
		console.log "Inside run....."

module.exports = StormTracker

#-------------------------------------------------------------------------------------------

if require.main is module

	config = require('../package').config
	global.config = config

	storm = null # override during dev
	agent = new StormTracker
	agent.run storm
