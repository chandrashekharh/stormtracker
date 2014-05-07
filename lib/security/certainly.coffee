fs = require("fs")
puts = require("util").debug
inspect = require("util").inspect
certgen = require("security/certgen")


init = (config,temp) ->
	certgen.CONFIG_DIR = config
	certgen.TEMP_DIR = temp

notPresent = (certRequest, required) ->
	for v in required
		unless certRequest[v]
			return v
	return false

genCA = (certRequest,callback) ->
	error = null
	if err =  notPresent certRequest, ["subject", "daysValidFor"]
		throw Error("You must supply subject & daysValidFor")
	subject = certRequest.subject

	certgen.genSelfSigned subject, certRequest.daysValidFor, (err, key, cert)->
		throw err if err?
		certRequest.privateKey = key.toString()
		certRequest.cert = cert.toString()
		certRequest.selfSigned = true
		# delete subject.id
		callback(certRequest)


genKey = (certRequest,callback) ->
	certgen.genKey (err, privateKey) ->
		throw err if err?
		certRequest.privateKey = privateKey.toString()
		callback(certRequest)

newCSR = (certRequest,callback) ->
	if error = notPresent certRequest, ["subject","privateKey"]
		throw Error("You must supply a subject and privateKey")
	certgen.genCSR certRequest.privateKey, certRequest.subject, (err, csr) ->
		throw err if err?
		result =
			signee:	certRequest
			csr: csr.toString()
		callback(result)

signCSR = (csrRequest,callback) ->
	caCert=caKey=""
	if error = notPresent csrRequest, ["csr", "signer", "signee"]
		return callback new Error("You must supply signer & signee")
	certgen.signCSR csrRequest.csr, csrRequest.signer.cert, csrRequest.signer.privateKey, csrRequest.signee.daysValidFor, (err, finalCert) ->
		return callback err if err?
		csrRequest.signee.cert = finalCert.toString()
		csrRequest.signee.signer = csrRequest.signer
		callback null, csrRequest.signee

genCABundle = (certificate) ->
	ca = certificate.cert;
	if certificate.signer
		ca += genCABundle certificate.signer
	ca

pkcs12 = (certRequest,callback) ->
	unless certRequest.certificate? and certRequest.caBundle?
		throw Error("You must supply a certificate and caBundle.")
	ca = certRequest.caBundle
	certificate = certRequest.certificate;
	puts ca
	if certificate.privateKey?
		certgen.pkcs12 certificate.privateKey, certificate.cert, ca, certificate.subject.CN, (err, pkcs)->
			throw err if err?
			certRequest.certificate.pkcs12 = pkcs.toString("base64")
			outCertRequest = certRequest
	else
		certgen.pcs12 certificate.cert, ca, certificate.subject.CN, (err, pkcs)->
			throw err if err?
			certRequest.certificate.pkcs12 = pkcs.toString("base64")
			callback(certRequest)


sign = (certRequest, callback) ->
	if error = notPresent certRequest, ["cert", "privateKey", "ca", "message"]
		return reporterror response, "You must supply a #{error}"
	certgen.sign certRequest.cert, certRequest.privateKey, certRequest.ca, new Buffer(certRequest.message, "base64"), (error, results) ->
	puts results.toString("base64")
	callback {result:results.toString("base64")}


exports.genCA = genCA
exports.genKey = genKey
exports.newCSR = newCSR
exports.signCSR = signCSR
exports.pkcs12 = pkcs12
exports.sign = sign
exports.init = init
