jsonschema = require("json-schema")
uuid = require("node-uuid")
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
			serialkey: {"type":"string","required":true}
			lastActivation : {"type":"string","required":false}
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
				entry.id = key
                #console.log "loading key #{key} and val #{val}"
				@add key, entry

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

	validate : (paramId, bodyId, body) ->
		unless paramId == bodyId
			throw new Error "id does not match with url"

		try
			entry = new AgentsData bodyId, body
		catch err
			throw new Error "invalid json data"

	update : (id,agent) ->
		_agent = @db.get id
		if not _agent?
			return null
		else
            if agent.data?.bolt?.ca?
            	delete agent.data.bolt.ca
		try
			entry = new AgentsData _agent.id, agent
			@db.update  _agent.id, entry
		catch err
			throw new Error "invalid json data"


	create : (agent) ->
		agent.id?=uuid.v4()
		try
			entry = new AgentsData agent.id, agent
			@db.add agent.id, entry
			return entry
		catch err
			throw new Error "invalid json data"

	getAgent : (id) ->
		@db.get id

	getAgentBySerial : (serialKey) ->
		agents = query @db.db, {"serialkey":serialKey}

		if agents?
			return agents[0]

	deleteAgent : (id) ->
		@db.remove id


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
			@send AM.loadCaBundle(agent.data)
		catch error
			console.log "Error:"+error
			@response.send 400, error

	@put "/agents/:id": ->
		try
			entry = AM.getAgent @params.id
			if entry?
				AM.validate @params.id, @body.id, @body
				delete @body.bolt.ca if @body.bolt?.ca
				resp =  AM.update @body.id, @body
				@send resp.data
			else
				@send 404
		catch error
			@response.status(400)
			@response.send error: "#{error}"

	@put "/agents/:id/status/:status" : ->
		agent = @db.get @params.id
		if agent?
			agent.status = @params.status
			AM.update @params.id, agent
		else
			@send 404
		@send 204 #Just updated, but no return content

	@get "/agents/:id": ->
		agent = AM.getAgent @params.id
        #console.log "Ravi - get agent found ", agent
		if agent?
			@send AM.loadCaBundle(agent.data)
		else
			@send 404

	@get "/agents/:id/bolt": ->
		agent = AM.getAgent @params.id
		if agent?
			@send AM.loadCaBundle(agent.data).bolt
		else
			@send 404

	@get "/agents/serialkey/:key",auth, ->
		agent = AM.getAgentBySerial @params.key
		if agent?
			@send {"id":agent.id,"serialkey":@params.key}
		else
			@send 404

	@post "/agents/:id/csr", auth, ->
		util.log "CSR for agent #{@params.id}"
		if (AM.getAgent @params.id)?
			csrRequest =
				csr : @body.file
				signee :
					"daysValidFor": global.config.signerChain.days
				signer : AM.CM.get AM.stormsigner
			AM.CM.signCSR csrRequest, (err,cert) =>
				return @response.send 400 if err?
				@response.send {"encoding": "base64", "data": new Buffer(cert.cert).toString("base64")}
		else
			@send 404

	@del "/agents/:id", ->
		if (AM.getAgent @params.id)?
			AM.deleteAgent @params.id
			@send 204
			return
		@send 404

exports.AgentsManager = AgentsManager
exports.AgentsRegistry = AgentsRegistry
