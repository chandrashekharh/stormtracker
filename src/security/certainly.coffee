fs = require("fs")
puts = require("util").debug
inspect = require("util").inspect
parameters = require("http/parameters").parameters
certgen = require("security/certgen")


notPresent = (certRequest, required) ->
	for v in required
		unless certRequest[v]
			return v
	return false

genCA = (certRequest) ->
	outCertRequest = null
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
		outCertRequest = certRequest
	outCertRequest

genKey = (certRequest) ->
	outCertRequest = certRequest
	certgen.genKey (err, privateKey) ->
		throw err if err?
		certRequest.privateKey = privateKey.toString()
		outCertRequest = certRequest
	outCertRequest


newCSR = (certRequest) ->
	outCertRequest = certRequest
	if error = notPresent certRequest, ["subject","privateKey"]
		return reportError response, "You must supply a #{error}"
	certgen.genCSR certRequest.privateKey, certRequest.subject, (err, csr) ->
		throw err if err?
		result =
			signee:
				certRequest
		 csr:csr.toString()
		outCertRequest = result
	outCertRequest

signCSR = (certRequest) ->
	outCertRequest = null
	caCert=caKey=""
	if error = notPresent certRequest, ["csr", "signer", "signee"]
		return reportError response, "You must supply a #{error}"
	certgen.signCSR certRequest.csr, certRequest.signer.cert, certRequest.signer.privateKey, certRequest.signee.daysValidFor, (err, finalCert) ->
		throw err if err?
	certRequest.signee.cert = finalCert.toString()
	certRequest.signee.signer = certRequest.signer
	outCertRequest = certRequest

genCABundle = (certificate) ->
	ca = certificate.cert;
	if certificate.signer
		ca += genCABundle certificate.signer
	ca

pkcs12 = (certRequest) ->
	outCertRequest = null
	unless certRequest.certificate? and certRequest.caBundle?
		return reportError response, "You must supply a certificate and caBundle."
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
			outCertRequest = certRequest
	outCertRequest


sign = (certRequest) ->
	outCertRequest = certRequest
	if error = notPresent certRequest, ["cert", "privateKey", "ca", "message"]
		return reporterror response, "You must supply a #{error}"
	certgen.sign certRequest.cert, certRequest.privateKey, certRequest.ca, new Buffer(certRequest.message, "base64"), (error, results) ->
	puts results.toString("base64")
	outCertRequest = {result:results.toString("base64")}



exports.genCA = genCA
exports.genKey = genKey
exports.newCSR = newCSR
exports.signCSR = signCSR
exports.pkcs12 = pkcs12
exports.sign = sign
