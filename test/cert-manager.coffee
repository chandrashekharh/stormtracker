CertificateManager = require("../lib/http/certs").CertificateManager
Certificate = require("../lib/security/certificate").Certificate
uuid = require("uuid")
fs = require("fs")
DEFAULT_CONFIG = "stormtracker.json"

GLOBAL.config = JSON.parse fs.readFileSync process.cwd()+"/"+DEFAULT_CONFIG


certobj = {
	"subject": {
		"emailAddress": "certs@clearpathnet.com",
		"subjectAltName": "email:copy",
		"nsComment": "UUID:"+uuid.v4(),
		"pathlen": -1,
		"C": "US",
		"O": "ClearPath Networks",
		"OU": "VSP",
		"CA": true,
		"CN": "Test Root Signer",
		"L": "El Segundo",
		"ST": "CA"
	},
	"daysValidFor": 7300,
	"selfSigned": true,
	"upstream" : false,
	"downstream" : false
}


assert = require("assert")
cm = new CertificateManager("config","temp")
clone = (cert) ->
	JSON.parse JSON.stringify cert


describe "CertificateManager", ->
	describe "#create()", ->
		it "Must create the self signed certificate if selfSigned is true",(done) ->
			certobj.id = uuid.v4()
			cm.create certobj, (err,cert) ->
				assert.notEqual cert.privateKey,""
				done()

	describe "#create(signed)",->
		it "Must create the signed certificate",(done) ->
			certobj.id = uuid.v4()
			cm.create certobj, (err,cert) -> #create the self signed
				signedCert = clone(cert)
				signedCert.selfSigned = false
				signedCert.signer = cert.id
				signedCert.subject.emailAddress = "stormtracker@clearpathnet.com"
				signedCert.subject.CN = "stormtracker@clearpathnet.com"
				signedCert.subject.nsComment = "UUID:"+uuid.v4()
				signedCert.privateKey = ""
				signedCert.cert = ""

				cm.create signedCert, (err,cert) ->
					console.log JSON.stringify err if err?
					assert.notEqual cert.cert,""
					assert.notEqual cert.privateKey, ""
					assert.equal cert.signer, certobj.id
					done()

	describe "#validate(cert)",->
		it "Must validate the certificate object", ->
			certificate = new Certificate()
			assert.equal certificate.validate(certobj),true
