jsonschema = require("json-schema")


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


class Certificate
	constructor: ->
		@certificateSchema = certificateSchema
	validate: (body) ->
		console.log 'performing schema validation on incoming certificate'
		throw new Error "No body as input" unless body
		result = jsonschema.validate body, @certificateSchema
		# console.log JSON.stringify result1
		# console.log JSON.stringify result2
		error = new Error("Invalid certificate posting!")
		error.cert_errors = result.errors
		throw error unless result.valid
		return result.valid


exports.Certificate = Certificate
