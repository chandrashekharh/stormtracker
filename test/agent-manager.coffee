global.config = require('../package').config

AgentManager = require("../lib/http/agents").AgentManager
CertificateManager = require("../lib/http/certs").CertificateManager
uuid = require("uuid")
fs = require("fs")
certainly = require("security/certainly")
HttpClient = require("../lib/http/client").HttpClient


agent ={
	"serialKey": "serial",
	"stoken": "stoken",
	"bolt": {
		"uplinks": [
		 "stormtower.dev.intercloud.net"
		],
	"beaconInterval": 10,
	"beaconRetry": 2,
	"uplinkStrategy": "roundrobin"
  }
}

assert = require("assert")
client = new HttpClient "localhost",8123

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
			client.post "/agents",agent,headers,(err,response)->
				console.log JSON.stringify response
				assert.equal response.serialKey,"serial"
				agent.id = response.id
				done()

		it "Must list the objects of agent", (done)->
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="
			client.post "/agents",agent,headers,(err,response)->
				assert.equal response.serialKey,"serial"
				client.get "/agents/"+response.id,headers,(err,response) ->
					assert.equal response.bolt.ca.encoding,"base64"
					done()

	describe "getAgentBySerial()", (done)->
		before (done)->
			headers = {}
			client.post "/agents",agent,headers,(err,response)->
				assert.equal response.serialKey,"serial"
				agent.id = response.id
				done()
		it "Must get the object via serialKey", ->
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="
			client.get "/agents/serialKey/#{agent.serialKey}",headers,(err,response)->
				assert.equal agent.serialKey,response.serialKey

	describe "signCSR()", ->
		cm = new CertificateManager
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
					client.post "/agents/#{agent.id}/csr",cabundle,headers,(err,response)->
						assert.equal response.encoding,"base64"
						assert.notEqual response.data,""
						done()

	describe "getBoltConfig()",->
		before (done)->
			headers = {}
			client.post "/agents",agent,headers,(err,response)->
				assert.equal response.serialKey,"serial"
				agent.id = response.id
				done()
		it "Get the bolt config", (done) ->
			headers =
				"Authorization" : "Basic YWdlbnQwMDc6cGFzc3dvcmQ="

			client.get "/agents/#{agent.id}/bolt",headers,(err,response) ->
				assert.equal response.cabundle.encoding,"base64"
				done()
