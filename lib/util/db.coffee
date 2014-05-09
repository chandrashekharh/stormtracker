dirty = require("dirty")


agents = ->
	dirty  GLOBAL.config.agentsDB
certs = ->
	dirty GLOBAL.config.certsDB

exports.agents = agents
exports.certs = certs
