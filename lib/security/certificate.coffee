jsonschema = require("json-schema")

certificatesubjectSchema =
	name : "CertificateSubject"
	type : "object"
	additionalProperties : true
	properties:
		id: {"type":"string","required":false}
		C: {"type":"string","required":true}
		ST: {"type":"string","required":true}
		L: {"type":"string","required":true}
		O: {"type":"string","required":true}
		OU: {"type":"string","required":true}
		CN: {"type":"string","required":true}
		email: {"type":"string","required":true}
		SAN: {"type":"string","required":true}
		nsComment: {"type":"string","required":true}
		pathlen: {"type":"number","required":true}
		CA: {"type":"boolean","required":true}

certificateSchema =
	name : "Certificate"
	type : "object"
	additionalProperties :  {"type":"string"}
	properties:
		id: {"type":"string","required":false}
		privateKey: {"type":"string","required":false}
		cert:  {"type":"string","required": true}
		subject: {"$ref":"CertificateSubject"}
		daysValidFor: {"type":"number","required": true}
		signer: {"type":"string","required": true}
		signees:
			items: {"type":"string"}
		selfSigned: {"type":"boolean","required": true}
		signedOn: {"type":"number","required": true}
		upstream: {"type":"boolean","required": true}
		downstream: {"type":"boolean","required": true}



class Certificate
	constructor: ->
		@schema = certificateSchema

	validate: (body) ->
		console.log 'performing schema validation on incoming certificate'
		return new Error "No body as input" unless body
		result = jsonschema.validate body, @schema
		console.log result
		return new Error "Invalid service openvpn posting!: #{result.errors}" unless result.valid
		return {"result":"success"}


exports.Certificate = Certificate
