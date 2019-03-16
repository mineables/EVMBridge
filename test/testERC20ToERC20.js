const Web3 = require('web3')
const web3 = new Web3()
var ERC20Portal = artifacts.require("./ERC20Portal.sol")
var NativePortal = artifacts.require("./ERC20Portal.sol")
var Bitcoin = artifacts.require("./_0xBitcoinToken.sol")

var HomeToken = artifacts.require("./HomeToken.sol")
var ForeignToken = artifacts.require("./ForeignToken.sol")

contract('ERC20Portal To Bridgeable Token Tests [testERC20ToERC20.js]', async (accounts) => {

    let bridgeUser = accounts[5]
    let STARTING_BALANCE = 5000

    before(async () => {
        
    })

    after(async () => {
        // runs after all tests in this block
    })

    it("configure the bridges", async () => {
        console.log('Note: these tests only cover whole value number transfers')
        let home = await HomeToken.deployed()
        let foreign = await ERC20Portal.deployed()
        let bitcoin = await Bitcoin.deployed()

        let tokensIn0xBTC = STARTING_BALANCE * Math.pow(10, 8)
        await bitcoin.transfer(bridgeUser, tokensIn0xBTC)
        console.log('Setup - bitcoin.balanceOf[bridgeUser]: ', readable((await bitcoin.balanceOf(bridgeUser)).toNumber(), 8))

        await home.addValidator(accounts[1])
        await home.addValidator(accounts[2])
        await home.pair(foreign.address)

        await foreign.addValidator(accounts[1])
        await foreign.addValidator(accounts[2])
        await foreign.pair(home.address)

        console.log('bridged tokens configured')
    })

    it("should test transfer of 300 from foreign to home", async () => {
        let home = await HomeToken.deployed()
        let foreign = await ERC20Portal.deployed()
        let bitcoin = await Bitcoin.deployed()

        let homeBalance = readable((await home.balanceOf(bridgeUser)))
        let bitcoinBalance = readable((await bitcoin.balanceOf(bridgeUser)), 8)
        console.log('Before - home.balanceOf: ', parseInt(homeBalance))
        console.log('Before - bitcoin.balanceOf: ', bitcoinBalance)
        assert.equal(STARTING_BALANCE, parseInt(homeBalance) + parseInt(bitcoinBalance))

        // important to remember that 0xBitcoin only has 8 decimals
        let tokens = 300
        let tokensIn0xBTC = tokens * Math.pow(10, 8)
        let tokensInNative = tokens * Math.pow(10, 18)
        // Step 1: User calls enter on foreign

        await bitcoin.approve(foreign.address, tokensIn0xBTC, { from: bridgeUser })
        let enterTxn = await foreign.enter(tokensIn0xBTC, { from: bridgeUser })

        // single call here
        // let enterTxn = await bitcoin.approveAndCall(foreign.address, tokensIn0xBTC, web3.utils.toHex(0), {from: bridgeUser})

        // We can loop through result.logs to see if we triggered the event.
        for (var i = 0; i < enterTxn.logs.length; i++) {
            var log = enterTxn.logs[i];

            if (log.event == "EnterBridgeEvent") {
                let result = log
                let fromAccount = result.args.from

                // Step 2: Validators sign transactions from bridge middleware. They are responsible for verifying
                // the home transaction tokens and originator account
                let contentHash = hashFunction(fromAccount, result.transactionHash, foreign.address, tokensInNative)
                let signatures = getValidatorSignatures(contentHash)
                // Step 2.1: Bridge middleware returns signed transactionss

                // Step 3: User calls exit on foreign contract with signed transactions
                await home.exit(result.transactionHash, foreign.address, tokensInNative.toString(), signatures, { from: bridgeUser })

                let homeBalance = readable((await home.balanceOf(bridgeUser)))
                let bitcoinBalance = readable((await bitcoin.balanceOf(bridgeUser)), 8)
                console.log('After - home.balanceOf: ', parseInt(homeBalance))
                console.log('After - bitcoin.balanceOf: ', bitcoinBalance)
                assert.equal(STARTING_BALANCE, parseInt(homeBalance) + parseInt(bitcoinBalance))

                break
            }
        }

    })

    it("should test transfer of 200 from home to foreign", async () => {
        let home = await HomeToken.deployed()
        let foreign = await ERC20Portal.deployed()
        let bitcoin = await Bitcoin.deployed()

        // important to remember that 0xBitcoin only has 8 decimals
        let tokens = 200
        let tokensIn0xBTC = tokens * Math.pow(10, 8)
        let tokensInNative = tokens * Math.pow(10, 18)

        let homeBalance = readable((await home.balanceOf(bridgeUser)))
        let bitcoinBalance = readable((await bitcoin.balanceOf(bridgeUser)), 8)
        console.log('Before - home.balanceOf: ', parseInt(homeBalance))
        console.log('Before - bitcoin.balanceOf: ', bitcoinBalance)
        assert.equal(STARTING_BALANCE, parseInt(homeBalance) + parseInt(bitcoinBalance))

        // Step 1: User calls enter on foreign
        let enterTxn = await home.enter(tokensInNative.toString(), { from: bridgeUser })

        // We can loop through result.logs to see if we triggered the event.
        for (var i = 0; i < enterTxn.logs.length; i++) {
            var log = enterTxn.logs[i];

            if (log.event == "EnterBridgeEvent") {
                let result = log
                let fromAccount = result.args.from
                // Step 2: Validators sign transactions from bridge middleware. They are responsible for verifying
                // the home transaction tokens and originator account
                let contentHash = hashFunction(fromAccount, result.transactionHash, home.address, tokensIn0xBTC)
                let signatures = getValidatorSignatures(contentHash)
                // Step 2.1: Bridge middleware returns signed transactionss

                // Step 3: User calls exit on foreign contract with signed transactions
                await foreign.exit(result.transactionHash, home.address, tokensIn0xBTC.toString(), signatures, { from: bridgeUser })

                let homeBalance = readable((await home.balanceOf(bridgeUser)))
                let bitcoinBalance = readable((await bitcoin.balanceOf(bridgeUser)), 8)
                console.log('After - home.balanceOf: ', parseInt(homeBalance))
                console.log('After - bitcoin.balanceOf: ', bitcoinBalance)
                assert.equal(STARTING_BALANCE, parseInt(homeBalance) + parseInt(bitcoinBalance))

                break
            }
        }

    })


    function readable(num, decimals = 18) {
        return num / Math.pow(10, decimals);
    }

    function hashFunction(from, txnHash, foreignAddress, amount) {
        var functionSig = web3.eth.abi.encodeFunctionSignature('entranceHash(bytes32,address,uint256)')

        let hash = web3.utils.keccak256(web3.eth.abi.encodeParameters(
            ['bytes4', 'address', 'bytes32', 'address', 'uint256'],
            [functionSig, from, txnHash, foreignAddress, web3.utils.toHex(amount)]
        ))
        return hash
    }

    function getValidatorSignatures(payload) {

        // signer pk
        let pkSigner = '0x705a6cdf0971421a29c9fc32ca446f96eb185d35b4532ce7d8f40db8f738e9ae'
        let pkSigner2 = '0x4ce8132cd559855ef760e215a5a26b05de525ee06c26cd95f1730ad14bd27b47'

        // signed by the verifiers
        var sig = web3.eth.accounts.sign(payload, pkSigner, true)
        var sig2 = web3.eth.accounts.sign(payload, pkSigner2, true)

        var combined = '0x' + sig.signature.substring(2) + sig2.signature.substring(2)
        return combined
    }

})
