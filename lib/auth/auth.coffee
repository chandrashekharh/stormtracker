query = require("dirty-query").query
db = require("util/db")
passport = require("passport")
BasicStrategy = require("passport-http").BasicStrategy
agentsDB = db.agents()
basicStrategy = new BasicStrategy (username,password,done)->
	process.nextTick ()->
		agents = query agentsDB, {"password":password}
		if agents.length == 0
			done null,false
		else
			user =
				username:username
				password : password
			done null,user


# @include = ->
#	@all "*",auth,->
#	user = @request.user
#	agent =
#		@next()
#	else
#		@response.statusCode = 401
#		@next("User is not authorized")


exports.BasicStrategy = basicStrategy
exports.authenticate = passport.authenticate 'basic', { session: false }
