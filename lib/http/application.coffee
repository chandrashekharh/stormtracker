certainly = require("security/certainly")
class StormTracker
	constructor: (@include) ->







class CertificateManager
	This = null
	constructor: (config,temp) ->
		@db = require("dirty") '/tmp/certs.db'
		console.log("Initialized dirty db")
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

	create: (cert,callback) ->
		if cert.signer == ""
			cert.selfSigned = true
			aCert = certainly.genCA cert, (cert) ->
				This.db.set cert.id,cert
		else
			certainly.genKey cert,(ocert) ->
				ocert = This.loadSigners ocert
				certainly.newCSR ocert,(csr) ->
					csr.signee = csr.signee
					csr.signer = ocert.signer
					certainly.signCSR csr,(err,cert)->
						return callback err if err?
						cert = This.unloadSigners cert
						This.db.set cert.id, cert
						callback null, cert


	# signCSR: (csrRequest, callback) ->

exports.StormTracker = StormTracker
exports.CertificateManager = CertificateManager
