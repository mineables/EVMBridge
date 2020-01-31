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
  node.on('peer:connect', (peer) => {
    console.log('Peer connection established to:', peer.id.toB58String())
  })
  // Emitted when a peer has been found
  node.on('peer:discovery', (peer) => {
    console.log('Peer discovered:', peer.id.toB58String())
  })

  await node.start()
  return node
}

// program entry point
;(async () => {
  const requestsTopic = 'request'
  const responsesTopic = 'response'

  const node1 = createNode()
  //await node1.dial(node2.peerInfo)

  await node1.pubsub.subscribe(responsesTopic, async(msg) => {
    console.log(`Response received: ${msg.data.toString()}`)
    await node1.pubsub.unsubscribe(responsesTopic, (msg) => { 
      console.log('unsubscribe msg: ' + msg) 
    })
  })

  setInterval(() => {
    // https://chainid.network/chains.json
    let tx = {
      chainId: 1,
      type: "transferHomeToForeign",
      txnHash: "0x83445ad0c995c35eb379218519508363ca60b28c883278b6202a57af723b1752" 
    }
    node1.pubsub.publish(requestsTopic, Buffer.from( JSON.stringify(tx)) )

  }, 1000)
})();