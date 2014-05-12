# default configuration will be in /etc/stormstack/stormtracker.json
fs = require("fs")
DEFAULT_PATH =  "/etc/stormstack"
DEFAULT_CONFIG = "stormtracker.json"

if fs.existsSync DEFAULT_PATH+"/"+DEFAULT_CONFIG
	GLOBAL.config = JSON.parse fs.readFileSync DEFAULT_PATH+"/"+DEFAULT_CONFIG
else if fs.existsSync process.cwd()+"/"+ DEFAULT_CONFIG
	GLOBAL.config = JSON.parse fs.readFileSync process.cwd()+"/"+DEFAULT_CONFIG
else
	clc = require("cli-color")
	console.log(clc.red("Global configuration not found. Can't start application"))
	process.exit(1)

passport = require("passport")
passport.use require("auth/auth").BasicStrategy

{@app} = require("zappajs")  GLOBAL.config.port,->
	@configure =>
		@use "bodyParser", "methodOverride",passport.initialize(), @app.router, "static"
		@set "basepath": "/v1.0"

	@configure
		development: => @use errorHandler: {dumpExceptions: on, showStack: on}
		production: => @use errorHandler

	@include "./lib/http/certs"
	@include "./lib/http/agents"
