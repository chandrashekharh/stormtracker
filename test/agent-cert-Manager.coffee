chai = require("chai")
expect = chai.expect
assert = require("chai").assert
expect = require("chai").expect
should = require("chai").should
global.staticdata = require('./default-configs')
util = require 'util'
uuid = require("uuid")
global.config = require('../package').config
AgentsManager = require('../lib/http/agents').AgentsManager
AgentsRegistry = require('../lib/http/agents').AgentsRegistry

CertificateRegistry = require("../lib/security/certificate").CertificateRegistry
certainly = require("../lib/security/certainly")
CertificateManager = require("../lib/http/certs").CertificateManager
CertificateFactory = require("../lib/http/certs").CertificateFactory


describe "Testing Agents and certs Manager Functions", ->
    AM = CF = null
    console.log "Hello"
    before ->
        agentsdb = new AgentsRegistry "#{global.config.datadir}/agents.db"
        certsdb  = new CertificateRegistry "#{global.config.datadir}/certs.db"
        CF = new CertificateFactory(certsdb)
        it "#Create the stormtracker root certificates", ->
            result = CF.init()
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.exist
            util.log 'CF.init result: ' + util.inspect result

        AM = new AgentsManager(agentsdb,CF.CM)
        it "#Verify Agentmanager AM and CertificateFactory CF ", ->
            expect(AM,CF).not.to.be.instanceof(Error)
            expect(AM,CF).to.exist
            expect(AM).to.be.an.instanceof(AgentsManager)
            expect(CF).to.be.an.instanceof(CertificateFactory)

    describe 'Agent and certs functions verify', ->
        it "Validate agents body", ->
            result = AM.validate staticdata.agentdata.id, staticdata.agentdata.id, staticdata.agentdata.agentsconfigJSON
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.exist
            expect(staticdata.agentdata.agentsconfigJSON).to.be.an('object')
            expect(staticdata.agentdata.agentsconfigJSON.bolt).to.be.an('object')
            expect(staticdata.agentdata.agentsconfigJSON.bolt.uplinks).to.be.a('array')
            expect(staticdata.agentdata.agentsconfigJSON).to.contain.key('serialkey','stoken','bolt')
            expect(staticdata.agentdata.agentsconfigJSON.bolt).to.contain.key('beaconInterval','beaconRetry','uplinkStrategy')

        it "Create agents", ->
            result = AM.create staticdata.agentdata.agentsconfigJSON
            staticdata.agentdata.id = result.id
            staticdata.agentdata.serialkey = result.data.serialkey
            expect(result).to.exist
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.contain.key('id','data')
            expect(result).to.be.an('object')
            expect(result.data).to.be.an('object')
            expect(result.data.bolt).to.be.an('object')
            expect(result.data.bolt.uplinks).to.be.a('array')
            expect(result).to.contain.key('log', 'validity','saved')
            expect(result.data).to.contain.key('serialkey','stoken','bolt','id')
            expect(result.data.bolt).to.contain.key('uplinks','beaconInterval','beaconRetry','uplinkStrategy')
            util.log "CREATE agents:  " + util.inspect result


        it "GET agents by ID", ->
            result = AM.getAgent staticdata.agentdata.id
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.contain.key('id','data')
            expect(result).to.be.an('object')
            expect(result.data).to.be.an('object')
            expect(result.data.bolt).to.be.an('object')
            expect(result.data.bolt.uplinks).to.be.a('array')
            expect(result).to.contain.key('log', 'validity','saved')
            expect(result.data).to.contain.key('serialkey','stoken','bolt','id')
            expect(result.data.bolt).to.contain.key('uplinks','beaconInterval','beaconRetry','uplinkStrategy')
            util.log "GET agents by ID:  " + util.inspect result

        it "GET agents serialkay", ->
            result = AM.getAgentBySerial staticdata.agentdata.serialkey
            util.log "GET agents serialkay: " + util.inspect result
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.be.an('object')
            expect(result).to.contain.key('id','data')
            expect(result).to.contain.key('log', 'validity','saved')
            expect(result.data).to.contain.key('serialkey','stoken','bolt','id')
            expect(result.data.bolt).to.contain.key('uplinks','beaconInterval','beaconRetry','uplinkStrategy')
            expect(result.data.bolt).to.contain.key('beaconValidity','allowRelay','relayPort','allowedPorts','listenPort')
            expect(result.data.bolt.uplinks).to.be.a('array')
            expect(result.data.bolt).to.be.an('object')

        it "Update agents", ->
            result = AM.update staticdata.agentdata.id, staticdata.agentdata.agentsconfigJSON
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.be.an('object')
            expect(result).to.contain.key('id','data')
            expect(result).to.contain.key('log', 'validity','saved')
            expect(result.data).to.contain.key('serialkey','stoken','bolt','id')
            expect(result.data.bolt).to.contain.key('uplinks','beaconInterval','beaconRetry','uplinkStrategy')
            expect(result.data.bolt.uplinks).to.be.a('array')
            expect(result.data.bolt).to.be.an('object')

        it "GET bolt CA bundle", ->
            agentconfigs = null
            agentconfigs = AM.getAgent staticdata.agentdata.id
            result = AM.loadCaBundle(agentconfigs.data).bolt
            expect(result).to.exist
            expect(result).not.to.be.instanceof(Error)
            expect(result).to.contain.key('uplinks')
            expect(result.uplinks).to.be.a('array')
            expect(result).to.contain.key('beaconInterval')
            expect(result).to.contain.key('beaconRetry')
            expect(result).to.contain.key('uplinkStrategy')
            expect(result).to.contain.key('ca')
            expect(result.ca).to.contain.key('encoding')
            expect(result.ca.encoding).to.equal('base64')
            expect(result.ca.data).to.not.empty('')

        it "SignCSR agents certs request", ->
            cabundle = csrRequest = [] 
            util.log "CSR for agent #{staticdata.agentdata.id}"
            cert = AM.CM.blankCert("agent1@clearpathnet.com","email:copy","agent007@clearpathnet.com",7600,false)
            certainly.genKey cert,(err,certRequest)->
                expect(certRequest).not.to.be.instanceof(Error)
                cabundle =
                    encoding:"base64"
                    data:new Buffer(csrRequest.csr).toString("base64")
            if (AM.getAgent staticdata.agentdata.id)?
                csrRequest =
                    csr : cabundle 
                    signee : "daysValidFor": global.config.signerChain.days
                    signer : AM.CM.get AM.stormsigner
                 util.log 'AM.CM.stormsigner request: ' + util.inspect csrRequest
                 result = AM.CM.signCSR csrRequest
                 expect(result).not.to.be.instanceof(Error)


        describe "Testing Certs Manager functions", ->
            it "Must get the certs", ->
                result = CF.CM.get 'stormtracker' 
                util.log 'CF.CM.GET: '  + util.inspect result
                expect(result).not.to.be.instanceof(Error)
                expect(result).to.contain.key('signer')
                expect(result).to.contain.key('subject')
                expect(result.subject).to.contain.key('emailAddress')
                expect(result.subject).to.contain.key('subjectAltName')
                expect(result.subject).to.contain.key('nsComment')
                expect(result).to.contain.key('daysValidFor','selfSigned','upstream','downstream','id')
                expect(result).to.contain.key('privateKey','cert','signer','saved')

        describe "Testing Certs Manager functions", ->
            it "Must get the signerbundle certs", ->
                result = CF.CM.signerBundle 'stormtracker'
                expect(result).not.to.be.instanceof(Error)
                expect(result).to.not.empty('')
                util.log 'CF.CM.signerbundle: '  + util.inspect result
        '''
        describe "Must get the  list of certs", ->
            it "Must get the list of certs", ->
                result = CF.CM.list 'stormtracker' 
                expect(result).not.to.be.instanceof(Error)
                util.log 'AM.CF.CM.list: '  + util.inspect result
        '''
        '''
        describe "Testing Certs Manager functions", ->
            cm = new CertificateManager("config","temp")
            #certsdb  = new CertificateRegistry "#{global.config.datadir}/certs.db"
            describe "CertificateManager", ->
                it "Must create the self signed certificate if selfSigned is true",(done) ->
                    staticdata.agentdata.certobj.id = uuid.v4()
                    staticdata.agentdata.certobj.subject.nsComment = 'UUID:' + staticdata.agentdata.certobj.id
                    util.log 'certs-id: '  + util.inspect staticdata.agentdata.certobj
                    signerChain = global.config.signerChain
                    util.log 'signerChain.days: '  + util.inspect signerChain.days
                    rootCert = cm.blankCert "root@clearpathnet.com","email:copy","StormTracker Root Signer",signerChain.days,true,true
                    rootCert.id= global.config.stormsigner
                    #rootCert.selfSigned= false
                    util.log "chandra: Signer chain created" + util.inspect rootCert
                    cm.create rootCert, (err,cert) ->
                        util.log JSON.stringify err if err?
                        util.log "chaan: Signer chain created"
                        expect(result).not.to.be.instanceof(Error)
                        done()
        '''
    after ->
        describe "Delete agents data", ->
            it "Delete agents data", ->
                result = AM.deleteAgent staticdata.agentdata.id
                expect(result).not.to.be.instanceof(Error)
                util.log 'DELETE agentID:  ' + util.inspect staticdata.agentdata.id 
