jsonschema = require("json-schema")
uuid = require("uuid")
CertificateManager = require("http/certs").CertificateManager
query = require("dirty-query").query
auth = require("http/auth").authorization
util = require "util"

StormAgent = require "stormagent"
StormData = StormAgent.StormData
StormRegistry = StormAgent.StormRegistry

class AgentsData extends StormData
	agentSchema =
		name : "Agent"
		type : "object"
		additionalProperties : true
		properties :
			id:		   {"type":"string","required":false}
			stoken:	   {"type":"string","required":true}
			serialKey: {"type":"string","required":false}
			bolt:
				type: "object"
				required: true
				additionalProperties : true
				properties:
					uplinks:
						type: "array"
						items:	{ type:"string", required:false}
					uplinkStrategy: { type: "string", required: false }
					allowRelay:		{ type: "boolean", required: false }
					relayPort:		{ type: "number", required: false }
					allowedPorts:
						type: "array"
						items: { type: "number", required: false }
					listenPort: { type: "number", required: false }
					beaconInterval: { type: "number", required: false }
					beaconRetry:	{ type: "number", required: false }
					beaconValidity: { type: "number", required: false }
					ca:
						type: "object"
						required : false
						properties:
							encoding: {"type":"string", "required":true}
							data:  {"type":"string", "required":true}
	constructor :(id,data) ->
		super id, data, agentSchema


class AgentsRegistry extends StormRegistry
	constructor :(filename) ->
		@on "load", (key,val) ->
			entry = new AgentsData key, val
			if entry?
				entry.saved = true
				@add key, val

		@on 'removed', (entry) ->
			entry.destroy() if entry.destroy?

		super filename

		get: (key) ->
			entry = super key

class AgentsManager
	constructor : (db,certMangr)->
		@db = db
		@stormsigner = global.config.stormsigner
		@CM = certMangr

	update : (id,agent) ->
		_agent = @db.get id
		if not _agent?
			return null

		if @validate agent
			@db.add _agent.id, agent

	create : (agent) ->
		agent.id = uuid.v4()
		@db.add agent.id, agent
		return agent

	getAgent : (id) ->
		@db.get id

	getAgentBySerial : (serialKey) ->
		agents = query @db, {"serialKey":serialKey}
		if agents?
			return agents[0]

	deleteAgent : (id) ->
		@db.rm id


	loadCaBundle: (agent) ->
		agent.bolt.ca =
			encoding : "base64"
			data : new Buffer(@CM.signerBundle @stormsigner).toString("base64")
		agent


@include = ->
	AM = @settings.agent.AM

	@post "/agents" : ->
		try
			agent =	 AM.create @body
			@send AM.loadCaBundle(agent)
		catch error
			@response.send 400, error

	@put "/agents/:id",auth, ->
		try
			if AM.validate @body
				@send AM.update @body.id,@body
		catch error
			@response.send 400, error

	@put "/agents/:id/status/:status" : ->
		agent = @db.get @params.id
		if agent?
			agent.status = @params.status
			AM.update @params.id, agent
		else
			@send 404
		@send 204 #Just updated, but no return content

	@get "/agents/:id", auth, ->
		agent = AM.getAgent @params.id
		if agent?
			@send AM.loadCaBundle(agent)
		else
			@send 404

	@get "/agents/:id/bolt", auth, ->
		agent = AM.getAgent @params.id
		if agent?
			@send AM.loadCaBundle(agent).stormbolt
		else
			@send 404

	@get "/agents/serialKey/:key",auth, ->
		agent = AM.getAgentBySerial @params.key
		if agent?
			@send AM.loadCaBundle(agent)
		else
			@send 404

	@post "/agents/:id/csr", auth, ->
		console.log "CSR for agent #{@params.id}"
		if (AM.getAgent @params.id)?
			csrData = new Buffer(@body.data,@body.encoding).toString()
			csrRequest =
				csr : csrData
				signee :
					"daysValidFor": global.config.signerChain.days
				signer : AM.CM.get AM.stormsigner
			AM.CM.signCSR csrRequest, (err,cert) =>
				@response.send 400 if err?
				@response.send {"encoding": "base64", "data": new Buffer(cert.cert).toString("base64")}
		else
			@send 404

	@del "/agents/:id", auth : ->
		if (@db.get @params.id)?
			@db.rm @params.id
			@send 204
			return
		@send 404

exports.AgentsManager = AgentsManager
exports.AgentsRegistry = AgentsRegistry
