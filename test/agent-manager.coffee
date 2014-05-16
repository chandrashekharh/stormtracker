AgentManager = require("../lib/http/agents").AgentManager
CertificateManager = require("../lib/http/certs").CertificateManager
uuid = require("uuid")
fs = require("fs")
certainly = require("security/certainly")
HttpClient = require("../lib/http/client").HttpClient

GLOBAL.config = require('../package').config
agent =
	serialKey : "serial"
	stoken :"sometoken"
	password : "password"
	stormbolt :
		state : "ACTIVE"
		servers : ["bolt://testserver"]
		beacon :
			interval : 2000
			retry : 2000
		loadbalance :
			algorithm : "roundrobin"
		cabundle:
			encoding:"base64"
			data :"base64 encoded certificate"

assert = require("assert")
cm = new CertificateManager("config","temp")
client = new HttpClient "localhost",5000

describe "AgentManager", ->

	# describe "create()", ->
	#	it "Must create the agent object", (done)->
	#		headers = {}
	#		client.post "/agents",agent,headers,(response)->
	#			assert.equal response.password,"password"
	#			agent.id = response.id
	#			done()

	describe "getAgent()", ->
		before (done)->
			headers = {}
			client.post "/agents",agent,headers,(response)->
				assert.equal response.password,"password"
				agent.id = response.id
				done()

		it "Must list the objects of agent", (done)->
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="
			client.post "/agents",agent,headers,(response)->
				assert.equal response.password,"password"
				client.get "/agents/"+response.id,headers,(response) ->
					assert.equal response.stormbolt.cabundle.encoding,"base64"
					done()


	describe "getAgentBySerial()", (done)->
		before (done)->
			headers = {}
			client.post "/agents",agent,headers,(response)->
				assert.equal response.password,"password"
				agent.id = response.id
				done()
		it "Must get the object via serialKey", ->
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="
			client.get "/agents/serialKey/#{agent.serialKey}",headers,(response)->
				assert.equal agent.serialKey,response.serialKey

	describe "signCSR()", ->
		it "Must sign the csr request", (done)->
			cert = cm.blankCert("agent1@clearpathnet.com","email:copy","agent007@clearpathnet.com",7600,false)
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="

			certainly.genKey cert,(err,certRequest)->
				done(err) if err?
				certainly.newCSR certRequest , (err,csrRequest) ->
					done(err) if err?
					cabundle =
						encoding:"base64"
						data:new Buffer(csrRequest.csr).toString("base64")
					client.post "/agents/#{agent.id}/csr",cabundle,headers,(response)->
						assert.equal response.encoding,"base64"
						assert.notEqual response.data,""
						done()

	describe "getBoltConfig()",->
		before (done)->
			headers = {}
			client.post "/agents",agent,headers,(response)->
				assert.equal response.password,"password"
				agent.id = response.id
				done()
		it "Get the bolt config", (done) ->
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="

			client.get "/agents/#{agent.id}/bolt",headers,(response) ->
				assert.equal response.cabundle.encoding,"base64"
				done()
