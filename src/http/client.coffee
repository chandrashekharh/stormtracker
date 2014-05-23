http = require("http")

class HttpClient
	constructor: (@host, @port) ->

	get:(path,headers,callback = ->)->
		this.send path,null,headers,"GET",callback

	post:(path, data,headers, callback = ->) ->
		this.send path, data, headers, "POST", callback
	put:(path, data, callback = ->) ->
		this.send path, data,headers, "PUT", callback
	delete:(path, data,headers, callback = ->) ->
		this.send path, data,headers, "DELETE", callback

	send:(path, data, headers,method, callback = ->)->
		headers["content-type"]="application/json"
		request = http.request(
			host:@host
			port:@port
			path:path
			method:method
			headers:headers
		,(response) ->
			body = ""
			response.on "data", (chunk) ->
				body += chunk
			response.on "end", ->
				if response.statusCode == 200
					ctype = response.headers["content-type"].split(";")
					if "application/json" is ctype[0].trim()
						body = JSON.parse body
						callback null, body
				else
					err = new Error "Not a proper response, status code="+response.statusCode
					err.statusCode = response.statusCode
					callback err,null
			response.on "error",(error)->
				callback error,null
			)
		request.on "error", (error)->
			callback(error,null)
		request.write JSON.stringify data if data
		request.end()

exports.HttpClient = HttpClient
