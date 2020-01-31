'use strict'

const Web3 = require('web3')
const homeWeb3 = new Web3()
const foreignWeb3 = new Web3()
const erc20PortalJson = require('./build/contracts/ERC20Portal.json')
const bridgeableTokenJson = require('./build/contracts/Bridgeable.json')
const erc20Json = require('./build/contracts/ERC20Interface.json')
require('dotenv').config()

const Libp2p = require('libp2p')
const TCP = require('libp2p-tcp')
const Mplex = require('libp2p-mplex')
const SECIO = require('libp2p-secio')
const PeerInfo = require('peer-info')
const Gossipsub = require('libp2p-gossipsub')

// use an example list of network bootstrappers
const bootstrapers = require('bootstrappers')

// create node function
const createNode = async () => {
  const peerInfo = await PeerInfo.create()
  peerInfo.multiaddrs.add('/ip4/0.0.0.0/tcp/0')

  const node = await Libp2p.create({
    peerInfo,
    modules: {
      transport: [TCP],
      streamMuxer: [Mplex],
      connEncryption: [SECIO],
      pubsub: Gossipsub
    },
    config: {
      peerDiscovery: {
        bootstrap: {
          interval: 60e3,
          enabled: true,
          list: bootstrapers
        }
      },
      pubsub: {
        enabled: true,
        emitSelf: false
      }
    }

  })

  // peer discovery events
  //node.peerInfo.multiaddrs.add('/ip4/0.0.0.0/tcp/0')
  node.on('peer:connect', (peer) => {
    console.log('Peer connection established to:', peer.id.toB58String())  // Emitted when a peer has been found
  })
  // Emitted when a peer has been found
  node.on('peer:discovery', (peer) => {
    console.log('Peer discovered:', peer.id.toB58String())
  })

  await node.start()
  return node
}

// request to transfer Home To Foreign
const transferHomeToForeign = async (request) => {
    console.log(bridgeableToken)
    let logs = await bridgeableToken.getPastEvents('EnterBridgeEvent', {
        fromBlock: 0,
        toBlock: 'latest'
    })
    console.log(logs)

    let log = logs.find(log => log.transactionHash === request.txnHash)
    if (!log) {
        console.log(`transactionHash: ${request.txnHash} was not found on home blockchain`)
        throw `transactionHash ${request.txnHash} was not found on home blockchain`
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

    return exitPacket
}

const transferForeignToHome = async (request) => {
    let logs = await erc20Portal.getPastEvents('EnterBridgeEvent', {
        fromBlock: 0,
        toBlock: 'latest'
    })

    let log = logs.find(log => log.transactionHash === request.txnHash)
    if (!log) {
        console.log(`transactionHash: ${request.txnHash} was not found on home blockchain`)
        throw `transactionHash ${request.txnHash} was not found on home blockchain`
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

    return exitPacket
}

const hashFunction = (from, txnHash, foreignAddress, amount) => {
    let web3 = homeWeb3
    var functionSig = web3.eth.abi.encodeFunctionSignature('entranceHash(bytes32,address,uint256)')

    let hash = web3.utils.keccak256(web3.eth.abi.encodeParameters(
        ['bytes4', 'address', 'bytes32', 'address', 'uint256'],
        [functionSig, from, txnHash, foreignAddress, web3.utils.toHex(amount)]
    ))
    return hash
}

const getValidatorSignature = (payload) => {
    let web3 = homeWeb3
    // signed by the verifier
    var sig = web3.eth.accounts.sign(payload, process.env.PRIVATE_KEY, true)
    return sig.signature
}

// program entry point
;(async () => {
  const requestsTopic = 'request'
  const responsesTopic = 'response'

  const node1 = createNode()
  //await node1.dial(node2.peerInfo)

  await node1.pubsub.subscribe(requestsTopic, (msg) => {
    console.log(`Request received: ${msg.data.toString()}`)

    // transferHomeToForeign, transferForeignToHome

    // sign and broadcast
    node1.pubsub.publish(responsesTopic, Buffer.from( JSON.stringify(tx)) )
    
  })
  
})();
