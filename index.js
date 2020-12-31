const express = require('express')
const Web3 = require('web3')
const homeWeb3 = new Web3()
const foreignWeb3 = new Web3()
const erc20PortalJson = require('./build/contracts/ERC20Portal.json')
const bridgeableTokenJson = require('./build/contracts/Bridgeable.json')
const erc20Json = require('./build/contracts/ERC20Interface.json')

require('dotenv').config()

LATEST_FROM_BLOCKS = process.env.LATEST_FROM_BLOCKS || 1000

var app = express()
app.use(express.json())
app.set('json spaces', 2)
app.use(function(err, req, res, next) {
    console.error(err.stack)
    res.status(500).send(err.stack)
})
app.use(express.static('web'))

var erc20Portal, bridgeableToken, erc20

app.listen(process.env.PORT, async () => {
    console.log('Welcome to Token Bridge 0.1 alpha')
    console.log('Running on http://127.0.0.1:' + process.env.PORT)
    homeWeb3.setProvider(process.env.HOME_ETHEREUM_PROVIDER_URL)
    foreignWeb3.setProvider(process.env.FOREIGN_ETHEREUM_PROVIDER_URL)
    erc20Portal = new foreignWeb3.eth.Contract(erc20PortalJson.abi, process.env.FOREIGN_PORTAL_CONTRACT)
    bridgeableToken = new homeWeb3.eth.Contract(bridgeableTokenJson.abi, process.env.HOME_BRIDGEABLE_CONTRACT)
    erc20 = new foreignWeb3.eth.Contract(erc20Json.abi, process.env.TOKEN_CONTRACT)
})

// wrap catches for asyn calls
const asyncMiddleware = fn =>
    (req, res, next) => {
        Promise.resolve(fn(req, res, next))
            .catch(next);
    }

// displays title and information about the service
app.get('/', function(request, response) {
    response.json('TokenPortal')
})

app.get('/transactions/:address', asyncMiddleware(async (request, response, next) => {

    var latest = await foreignWeb3.eth.getBlockNumber()
    var latestFrom = latest - LATEST_FROM_BLOCKS
    let foreignEnterlogs = await erc20Portal.getPastEvents('EnterBridgeEvent', {
        filter: { from: request.params.address },
        fromBlock: latestFrom,
        toBlock: 'latest'
    })
    let foreignExitlogs = await erc20Portal.getPastEvents('ExitBridgeEvent', {
        filter: { from: request.params.address },
        fromBlock: latestFrom,
        toBlock: 'latest'
    })

    latest = await homeWeb3.eth.getBlockNumber()
    latestFrom = latest - LATEST_FROM_BLOCKS
    let homeEnterLogs = await bridgeableToken.getPastEvents('EnterBridgeEvent', {
        filter: { from: request.params.address },
        fromBlock: latestFrom,
        toBlock: 'latest'
    })
    let homeExitLogs = await bridgeableToken.getPastEvents('ExitBridgeEvent', {
        filter: { from: request.params.address },
        fromBlock: latestFrom,
        toBlock: 'latest'
    })

    let allTxns = {}
    allTxns.foreign = {}
    allTxns.home = {}
    allTxns.foreign.Enterlogs = foreignEnterlogs
    allTxns.foreign.Exitlogs = foreignExitlogs
    allTxns.home.EnterLogs = homeEnterLogs
    allTxns.home.ExitLogs = homeExitLogs
    response.json(allTxns)
}))

// curl -d '{ "txnHash": "0x83445ad0c995c35eb379218519508363ca60b28c883278b6202a57af723b1752" }' -H "Content-Type: application/json" http://127.0.0.1:4000/foreign/verify
app.post('/foreign/verify', asyncMiddleware(async (request, response, next) => {

    let logs = await erc20Portal.getPastEvents('EnterBridgeEvent', {
        fromBlock: 0,
        toBlock: 'latest'
    })

    let log = logs.find(log => log.transactionHash === request.body.txnHash)
    if (!log) {
        console.log(`transactionHash: ${request.body.txnHash} was not found on home blockchain`)
        throw `transactionHash ${request.body.txnHash} was not found on home blockchain`
    }
    let txnHash = log.transactionHash
    let tokens = log.returnValues.amount
    let fromAccount = log.returnValues.from
    let decimals = await erc20.methods.decimals().call()
    let baseTokenAmount = tokens / Math.pow(10, decimals)
    let nativeTokenAmount = baseTokenAmount * Math.pow(10, 18)

    console.log(decimals, baseTokenAmount, nativeTokenAmount)
    console.log(fromAccount, txnHash, process.env.TOKEN_CONTRACT, tokens)

    let contentHash = hashFunction(fromAccount, txnHash, process.env.TOKEN_CONTRACT, nativeTokenAmount)
    let signatures = getValidatorSignature(contentHash)

    let exitPacket = {}
    exitPacket.transactionHash = txnHash
    exitPacket.foreignContract = process.env.TOKEN_CONTRACT
    exitPacket.tokens = nativeTokenAmount
    exitPacket.signatures = signatures

    response.json(exitPacket)
}))

// curl -d '{ "txnHash": "0x83445ad0c995c35eb379218519508363ca60b28c883278b6202a57af723b1752" }' -H "Content-Type: application/json" http://127.0.0.1:4000/home/verify
app.post('/home/verify', asyncMiddleware(async (request, response, next) => {

    console.log(bridgeableToken)

    let logs = await bridgeableToken.getPastEvents('EnterBridgeEvent', {
        fromBlock: 0,
        toBlock: 'latest'
    })

    console.log(logs)

    let log = logs.find(log => log.transactionHash === request.body.txnHash)
    if (!log) {
        console.log(`transactionHash: ${request.body.txnHash} was not found on home blockchain`)
        throw `transactionHash ${request.body.txnHash} was not found on home blockchain`
    }
    let txnHash = log.transactionHash
    let tokens = log.returnValues.amount
    let fromAccount = log.returnValues.from
    let decimals = await erc20.methods.decimals().call()
    let baseTokenAmount = tokens / Math.pow(10, 18)
    let erc20TokenAmount = baseTokenAmount * Math.pow(10, decimals)

    console.log(decimals, baseTokenAmount, erc20TokenAmount)
    console.log(fromAccount, txnHash, process.env.HOME_BRIDGEABLE_CONTRACT, tokens)

    let contentHash = hashFunction(fromAccount, txnHash, process.env.HOME_BRIDGEABLE_CONTRACT, erc20TokenAmount)
    let signatures = getValidatorSignature(contentHash)

    let exitPacket = {}
    exitPacket.transactionHash = txnHash
    exitPacket.foreignContract = process.env.HOME_BRIDGEABLE_CONTRACT
    exitPacket.tokens = erc20TokenAmount
    exitPacket.signatures = signatures

    response.json(exitPacket)
}))

function hashFunction(from, txnHash, foreignAddress, amount) {
    let web3 = homeWeb3
    var functionSig = web3.eth.abi.encodeFunctionSignature('entranceHash(bytes32,address,uint256)')

    let hash = web3.utils.keccak256(web3.eth.abi.encodeParameters(
        ['bytes4', 'address', 'bytes32', 'address', 'uint256'],
        [functionSig, from, txnHash, foreignAddress, web3.utils.toHex(amount)]
    ))
    return hash
}

function getValidatorSignature(payload) {
    let web3 = homeWeb3
    // signed by the verifier
    var sig = web3.eth.accounts.sign(payload, '0x' + process.env.PRIVATE_KEY, true)
    return sig.signature
}
