jsonschema = require("json-schema")
StormRegistry = require("stormagent").StormRegistry
StormData = require("stormagent").StormData

class Certificate extends StormData

	certificateSchema =
		name : "Certificate"
		type : "object"
		additionalProperties :  {"type":"string"}
		properties:
			id: {"type":"string","required":false}
			privateKey: {"type":"string","required":false}
			cert:  {"type":"string","required": false}
			daysValidFor: {"type":"number","required": true}
			signer: {"type":"string","required": false}
			selfSigned: {"type":"boolean","required": true}
			signedOn: {"type":"number","required": false}
			upstream: {"type":"boolean","required": true}
			downstream: {"type":"boolean","required": true}
			saved: {"type":"boolean","required": false}
			subject:
				type : "object"
				required : true
				additionalProperties : {"type":"string"}
				properties:
					C: {"type":"string","required":true}
					ST: {"type":"string","required":true}
					L: {"type":"string","required":true}
					O: {"type":"string","required":true}
					OU: {"type":"string","required":true}
					CN: {"type":"string","required":true}
					emailAddress: {"type":"string","required":true}
					subjectAltName: {"type":"string","required":true}
					nsComment: {"type":"string","required":true}
					pathlen: {"type":"number","required":true}
					CA: {"type":"boolean","required":true}


	constructor: (id, data) ->
		super id, data, certificateSchema

class CertificateRegistry extends StormRegistry
	constructor: (filename) ->
		@on 'load', (key,val) ->
			console.log "Inside load"
			entry = new Certificate key,val
			console.log key+":"+val
			if entry?
				entry.saved = true
				@add key, entry

		@on 'removed', (certificate) ->
			#Remove the certificate
		super filename

	get: (key) ->
		entry = super key

	# constructor: ->
	#	@certificateSchema = certificateSchema
	# validate: (body) ->
	#	console.log 'performing schema validation on incoming certificate'
	#	throw new Error "No body as input" unless body
	#	result = jsonschema.validate body, @certificateSchema
	#	# console.log JSON.stringify result1
	#	# console.log JSON.stringify result2
	#	error = new Error("Invalid certificate posting!")
	#	error.cert_errors = result.errors
	#	throw error unless result.valid
	#	return result.valid


exports.Certificate = Certificate
exports.CertificateRegistry = CertificateRegistry
