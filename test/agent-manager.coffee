AgentManager = require("../lib/http/agents").AgentManager
uuid = require("uuid")
fs = require("fs")
DEFAULT_CONFIG = "stormtracker.json"

GLOBAL.config = JSON.parse fs.readFileSync process.cwd()+"/"+DEFAULT_CONFIG

agent =
	serialKey : uuid.v4()
	password : uuid.v4()
	stormbolt :
		state : "ACTIVE"
		servers : ["bolt://testserver"]
		beacon :
			interval : 2000
			retry : 2000
		loadbalance :
			algorithm : "roundrobin"

assert = require("assert")
am = new AgentManager()

describe "AgentManager", ->
	describe "create()", ->
		it "Must create the agent object", ->
			agent = am.create(agent)
			assert.notEqual agent.id, null

	describe "getAgent()", ->
		it "Must list the objects of agent", ->
			agent = am.create(agent)
			agent2 = am.getAgent agent.id
			assert.equal agent.id, agent2.id

	describe "getAgentBySerial()", ->
		it "Must get the object via serialKey", ->
			agent2 = am.getAgentBySerial agent.serialKey
			assert.equal agent.serialKey,agent2.serialKey
