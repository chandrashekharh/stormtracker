certainly = require("security/certainly")
uuid = require("uuid")
Certificate = require("security/certificate").Certificate
db = require("util/db")
auth = require("auth/auth").authenticate

class CertificateManager
	This = null

	constructor: (config,temp) ->
		@db = db.certs()
		certainly.init config, temp
		This = this

	loadSigners: (cert) ->
		root = cert
		while root?
			root.signer = @db.get root.signer
			root = root.signer
		cert

	unloadSigners: (cert) ->
		root = cert
		while root.signer?
			acert = root.signer
			root.signer = acert.id
			root = acert
		cert

	get: (id) ->
		@db.get id

	list: () ->
		certs =[]
		@db.forEach (key,val)->
			certs.push {"id":val.id,"subject": val.subject,"signer":val.signer}
		certs

	resolveSigners : (cert) ->
		certs = []
		if not cert?
			return certs
		else
			certs.push cert
			signer = @db.get cert.signer
			if signer?
				certs = certs.concat(@resolveSigners(signer))
		certs

	signerBundle : (id) ->
		cert = @db.get id
		if cert?
			cabundle = ""
			for c in @resolveSigners(cert)
				cabundle +=c.cert
			cabundle
		else
			return null

	blankCert : (email,SAN,CN,days,isCA) ->
		return	certobj =
					"subject":
						"emailAddress": email
						"subjectAltName": SAN
						"nsComment": "UUID:"+uuid.v4()
						"pathlen": -1
						"C": "US"
						"O": "ClearPath Networks"
						"OU": "VSP"
						"CA": isCA
						"CN": CN
						"L": "El Segundo"
						"ST": "CA"
					"daysValidFor": days
					"selfSigned": false
					"upstream" : false
					"downstream" : false


	signCSR: (csr, callback) ->
		certainly.signCSR csr, (err, cert) ->
			return callback err if err?
			cert = This.unloadSigners cert
			callback null, cert

	create: (cert,callback) ->
		cert.id = uuid.v4()
		if cert.selfSigned
			cert.signer=""
			console.log "Creating self signed cert"
			certainly.genCA cert, (err,cert) ->
				return callback err if err?
				This.db.set cert.id,cert
				callback null,cert
		else
			console.log "Creating signed cert by "+cert.signer
			certainly.genKey cert,(err,ocert) ->
				return callback err if err?
				ocert = This.loadSigners ocert
				certainly.newCSR ocert,(err,csr) ->
					return callback err if err?
					csr.signer = ocert.signer
					certainly.signCSR csr,(err,cert)->
						return callback err if err?
						cert = This.unloadSigners cert
						This.db.set cert.id, cert
						callback null, cert


passport = require("passport")


@include = ->
	CM = new CertificateManager()
	certificate = new Certificate()

	@post "/cert" : ->
		Response = @response
		try
			if certificate.validate @body
				CM.create @body, (err,cert)=>
					return @response.send 400,err if err?
					@response.send cert
		catch error
			@response.send 400, error
			# @next error

	@get "/cert", auth, ->
		@send CM.list()


	@get "/cert/:id/signerBundle" : ->
		bundle = CM.signerBundle @params.id
		if not bundle?
			@send 404
			return
		@response.set "ContentType","application/x-pem-file"
		@response.set "Content-Disposition", "attachment; filename=caBundle.pem"
		@send bundle


	@get "/cert/:id/publicKey" : ->
		cert = CM.get @params.id
		if cert?
			@response.set "ContentType","application/x-pem-file"
			@response.set "Content-Disposition", "attachment; filename=private.pem"
			@send cert.cert
		else
			@send 404

	@get "/cert/:id/privateKey" : ->
		cert = CM.get @params.id
		if cert?
			@response.set "ContentType","application/x-pem-file"
			@response.set "Content-Disposition", "attachment; filename=private.pem"
			@send cert.privateKey
		else
			@send 404

	@get "/cert/:id" : ->
		cert = CM.get @params.id
		if cert?
			@send cert
		else
			@send 404

exports.CertificateManager = CertificateManager
