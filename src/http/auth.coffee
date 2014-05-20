passport = require("passport")
RestClient = require("http/client").HttpClient
util = require("util")
headers = {}
restClient = new RestClient global.config.stormkeeper.url,global.config.stormkeeper.port
BasicStrategy = require("passport-http").BasicStrategy
exports.BasicStrategy = new BasicStrategy (username,password,done)->
	process.nextTick ()->
		util.log "Logging with token "+username
		done null,{username:username,password:password,rules:["/agents/:id"]}
		# restClient.get "/tokens/"+username,headers,(err,response)->
		#	done null,false if err?
		#	restClient.get "/rules/"+response.rulesId,headers,(response)->
		#		done null,false if err?
		#		done null,{username:username,password:password,rules:response.rules}

exports.checkRule = (req,res,next) ->
	id = @params.id
	key = @params.key
	status = @params.status
	for rule in req.user.rules
		rule = rule.replace(":id",id) if id?
		rule = rule.replace(":key",id) if key?
		rule = rule.replace(":status",status) if status?
		if req.method+" "+req.originalUrl == rule
			next()
			return
	res.status(401)
	next("Forbidden")

# @include = ->
#	@all "*",auth,->
#	user = @request.user
#	agent =
#		@next()
#	else
#		@response.statusCode = 401
#		@next("User is not authorized")

exports.authenticate = passport.authenticate 'basic', { session: false }
exports.authorization = [exports.authenticate,exports.checkRule]
