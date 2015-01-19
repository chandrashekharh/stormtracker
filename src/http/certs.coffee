certainly = require('../security/certainly')
uuid = require("node-uuid")
CertificateRegistry = require('../security/certificate').CertificateRegistry
auth = require('../http/auth').authenticate
util = require "util"


class CertificateFactory
	constructor:(db)->
		@db = db
		@CM = new CertificateManager __dirname+"/../../"+global.config.folders.config, global.config.folders.tmp,@db

	init: ()->
		@db.on "ready",=>
			console.log "Finding the previously created signer chain "+global.config.stormsigner
			stormsigner = @db.get global.config.stormsigner
			console.log "Signer:"+ stormsigner
			if stormsigner?
				util.log "Signer chain already exists..skipping creation"
				return
			else
				signerChain = global.config.signerChain
				rootCert = @CM.blankCert "root@clearpathnet.com","email:copy","StormTracker Root Signer", signerChain.days,true,true
				rootCert.id= global.config.stormsigner
				@CM.create rootCert, (err,cert)->
					util.log JSON.stringify err if err?
					util.log "Signer chain created"

class CertificateManager

	constructor: (config,temp,db) ->
		certainly.init config, temp
		@db = db

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
		certs = [cert]
		if not cert?
			return certs
		else
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

	blankCert : (email,SAN,CN,days,isCA,selfSigned) ->
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
					"selfSigned": selfSigned
					"upstream" : false
					"downstream" : false


	signCSR: (csr, callback) ->
		certainly.signCSR csr, (err, cert) =>
			return callback err if err?
			cert = @unloadSigners cert
			callback null, cert

	create: (cert,callback) ->
		if cert.selfSigned
			cert.signer=""
			console.log "Creating self signed cert"
			certainly.genCA cert, (err,cert) =>
				return callback err if err?
				try
					@db.add cert.id,cert
				catch error
					callback error, null
				callback null,cert
		else
			console.log "Creating signed cert by "+cert.signer
			certainly.genKey cert,(err,ocert) =>
				return callback err if err?
				ocert = @loadSigners ocert
				certainly.newCSR ocert,(err,csr) =>
					return callback err if err?
					csr.signer = ocert.signer
					certainly.signCSR csr,(err,cert)=>
						return callback err if err?
						cert = @unloadSigners cert
						try
							@db.add cert.id, cert
						catch error
							callback error,null
						callback null, cert


passport = require("passport")

@include = ->
	CM = @settings.agent.CF.CM

	@post "/cert" : ->
		Response = @response
		CM.create @body, (err,cert)=>
			return @response.send 400,err if err?
			@response.send cert

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
exports.CertificateFactory = CertificateFactory
