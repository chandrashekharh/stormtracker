CertificateManager = require("../lib/http/application").CertificateManager


certobj = {
	"id": "a4990636-e5d2-435f-8502-76149ef4181a",
	"subject": {
		"id": "6399245e-7d5f-4ba7-9b77-23fc546503f6",
		"emailAddress": "certs@clearpathnet.com",
		"subjectAltName": "email:copy",
		"nsComment": "UUID:a4990636-e5d2-435f-8502-76149ef4181a",
		"pathlen": -1,
		"C": "US",
		"O": "ClearPath Networks",
		"OU": "VSP",
		"CA": "deva",
		"CN": "Hrvatski Root Signer",
		"L": "El Segundo",
		"ST": "CA"
	},
	"daysValidFor": 7300,
	"signer": "",
	"selfSigned": true,
	"signedOn": 1399073417023,
	"upstream" : false,
	"downstream" : false
}


uuid = require("uuid")

certobj.id = uuid.v4()

cm = new CertificateManager("config","temp")
certobj.signer ="a4990636-e5d2-435f-8502-76149ef4181a"
cm.create certobj, (err,cert)->
	console.log "Cert"+JSON.stringify cert
