jsonschema = require("json-schema")
uuid = require("uuid")
CertificateManager = require("http/certs").CertificateManager
query = require("dirty-query").query


agentSchema =
	name : "Agent"
	type : "object"
	additionalProperties : true
	properties :
		id: {"type":"string","required":false}
		serialKey: {"type":"string","required":false}
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
	This = null
	constructor : ->
		@agentSchema = agentSchema
		@CM = new CertificateManager "config", "temp"
		@db = require("dirty") GLOBAL.config.agentDB
		This = this
		@stormsigner = GLOBAL.config.stormsigner.id

	update : (id,agent) ->
		agent = @db.get id
		if not agent?
			return null

		if @validate agent
			@db.set agent.id, agent

	create : (agent) ->
		if @validate agent
			agent.id = uuid.v4()
			@db.set agent.id, agent
		return agent

	getAgent : (id) ->
		agent =  @db.get id
		if agent?
			return agent
		return ""

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


@include = ->
	AM = new AgentManager()

	@post "/agents" : ->
		try
			if AM.validate @body
				agent =  AM.create @body
				agent.cabundle.encoding = "base64"
				agent.cabundle.data = new Buffer(CM.signerBundle signerId).toString(agent.cabundle.encoding)
				@send agent
		catch error
			@response.send 400, error

	@put "agents/:id" : ->
		try
			if AM.validate @body
				@send AM.update @body
		catch error
			@response.send 400, error
	@put "agents/:id/status/:status" : ->
		agent = @db.get @params.id
		if agent?
			agent.status = @params.status
		else
			@send 404
		@send 204 #Just did it, but no return content

	@get "agents/:id" : ->
		agent = AM.getAgent @params.id
		if agent?
			@send agent
			return
		@send 404

	@get "agents/serialKey/:key" : ->
		agent = AM.getAgentBySerial @params.key
		if agent?
			agent.cabundle.encoding = "base64"
			agent.cabundle.data = new Buffer(CM.signerBundle signerId).toString(agent.cabundle.encoding)
			@send agent
			return
		@send 404

	@post "agents/:id/csr" : ->
		if AM.getAgent @params.id
			csrData = @body.data
			csrRequest =
				csr : csrData
				signee :
					"daysValidFor": GLOBAL.config.stormsigner.daysValidFor
				signer : CM.get @stormsigner
			CM.signCSR csrRequest, (err,cert) ->
				Response.send 400 if err?
				Response.send {"encoding": "base64", "data": new Buffer(cert.cert).toString("base64")}
		@send 404

	@del "agents/:id" : ->
		if (@db.get @params.id)?
			@db.rm @params.id
			@send 204
			return
		@send 404

exports.AgentManager = AgentManager
