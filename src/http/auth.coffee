passport = require("passport")
RestClient = require('../http/client').HttpClient
util = require("util")
headers = {}
restClient = new RestClient global.config.stormkeeper.url,global.config.stormkeeper.port
BasicStrategy = require("passport-http").BasicStrategy
query = require("dirty-query").query


FindAgent = (stoken,serial) ->
    dlist = global.agentsDB.list()
    if dlist
        newdlist = dlist.filter (entry) =>
            if entry and entry.data and entry.data.stoken is stoken and entry.data.serialkey is serial
                return true
    if newdlist?
        return newdlist[0]

exports.BasicStrategy = new BasicStrategy (username,password,done)->
    process.nextTick ()->
        if FindAgent(password,username)?
            util.log "Authentication succeeded"
            # done null,{username:username,password:password,rules:["/agents/:id"]}
            restClient.get "/tokens/"+password,headers,(err,response)->
                util.log "Authorization failed, err "+err if err? or not response?
                return done null,false if err? or not response?
                done null,{username:username,password:password,rules:response.rule.rules}
        else
            done null,false

exports.checkRule = (req,res,next) ->
    id = @params.id
    key = @params.key
    status = @params.status
    if req.user.rules?
        for rule in req.user.rules
            rule = rule.replace(":id",id) if id?
            rule = rule.replace(":key",key) if key?
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
