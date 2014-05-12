dirty = require("dirty")


certs = ->
	if GLOBAL.config?
		dirty GLOBAL.config.certsDB

agents = ->
	if GLOBAL.config?
		dirty  GLOBAL.config.agentsDB

exports.agents = agents
exports.certs = certs
