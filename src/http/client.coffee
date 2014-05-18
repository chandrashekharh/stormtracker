http = require("http")

class HttpClient
	constructor: (@host, @port) ->
	get:(path,headers,callback = ->)->
		http.get(
			host:@host
			port:@port
			path:path
			headers:headers
		,(result) ->
			body = ""
			result.on "data", (chunk) ->
				body += chunk
			result.on "end", ->
				ctype = result.headers["content-type"].split(";")
				if ctype[0].trim() is "application/json"
					body = JSON.parse body
					callback null, body if callback?
			result.on "error",(error)->
				callback error,null
				)

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
		,(result) ->
			body = ""
			result.on "data", (chunk) ->
				body += chunk
			result.on "end", ->
				ctype = result.headers["content-type"].split(";")
				if "application/json" is ctype[0].trim()
					body = JSON.parse body
					callback null, body
			result.on "error",(error)->
				callback error,null
			)
		request.write JSON.stringify data if data
		request.end()

exports.HttpClient = HttpClient
