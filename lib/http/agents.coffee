jsonschema = require("json-schema")
uuid = require("uuid")
CertificateManager = require("http/certs").CertificateManager
query = require("dirty-query").query
db = require("util/db")
auth = require("auth/auth").authenticate
util = require "util"

agentSchema =
	name : "Agent"
	type : "object"
	additionalProperties : true
	properties :
		id: {"type":"string","required":false}
		stoken: {"type":"string","required":true}
		serialKey: {"type":"string","required":false}
		password :{"type":"string","required":false}
		stormbolt:
			type: "object"
			required: true
			properties:
				state : {"type":"string", "required":true}
				servers:
					items:{"type": "string"}
				beacon:
					type: "object"
					required : false
					properties:
						interval:  {"type":"number","required":false}
						retry:  {"type":"number","required":false}
				loadbalance:
					type: "object"
					required : false
					properties:
						algorithm :{"type":"string", "required":false}
				cabundle:
					type: "object"
					required : false
					properties:
						encoding: {"type":"string", "required":true}
						data:  {"type":"string", "required":true}




class AgentManager
	constructor : ->
		@agentSchema = agentSchema
		@CM = new CertificateManager "config", "temp"
		@db = db.agents()
		@stormsigner = GLOBAL.config.stormsigner

	update : (id,agent) ->
		agent = @db.get id
		if not agent?
			return null

		if @validate agent
			@db.set agent.id, agent

	create : (agent) ->
		agent.id = uuid.v4()
		@db.set agent.id, agent
		return agent

	getAgent : (id) ->
		@db.get id

	getAgentBySerial : (serialKey) ->
		agents = query @db, {"serialKey":serialKey}
		if agents?
			return agents[0]

	deleteAgent : (id) ->
		@db.rm id

	validate: (body) ->
		console.log 'performing schema validation on incoming agent'
		return new Error "No body as input" unless body
		result = jsonschema.validate body, @agentSchema
		error = new Error("Invalid agent posting!")
		error.agent_errors = result.errors
		throw error unless result.valid
		return result.valid

	loadCaBundle: (agent) ->
		agent.stormbolt.cabundle =
			encoding : "base64"
			data : new Buffer(@CM.signerBundle @stormsigner).toString("base64")
		agent


@include = ->
	AM = new AgentManager()

	@post "/agents" : ->
		try
			if AM.validate @body
				agent =  AM.create @body
				@send AM.loadCaBundle(agent)
		catch error
			@response.send 400, error

	@put "/agents/:id",auth, ->
		try
			if AM.validate @body
				@send AM.update @body
		catch error
			@response.send 400, error

	@put "/agents/:id/status/:status" : ->
		agent = @db.get @params.id
		if agent?
			agent.status = @params.status
		else
			@send 404
		@send 204 #Just did it, but no return content

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
					"daysValidFor": GLOBAL.config.signerChain.days
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

exports.AgentManager = AgentManager
