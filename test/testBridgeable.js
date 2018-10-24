const Web3 = require('web3')
const web3 = new Web3()
var HomeToken = artifacts.require("./HomeToken.sol")
var ForeignToken = artifacts.require("./ForeignToken.sol")

contract('Bridgeable Tests [testBridgeable.js]', async (accounts) => {

    it("configure the bridge", async () => {
        let home = await HomeToken.deployed()
        let foreign = await ForeignToken.deployed()

        await home.addValidator(accounts[1])
        await home.addValidator(accounts[2])
        await home.pair(foreign.address)

        await foreign.addValidator(accounts[1])
        await foreign.addValidator(accounts[2])
        await foreign.pair(home.address)

        console.log('bridged tokens configured')
    })

    it("should sign and verify", async () => {
        let home = await HomeToken.deployed()
        let foreign = await ForeignToken.deployed()

        var functionSig = web3.eth.abi.encodeFunctionSignature('entranceHash(bytes32,address,uint256)')
        console.log(functionSig)

        let tokens = 300 * Math.pow(10, 18)
        // Step 1: User calls enter on home
        let enterTxn = await home.enter(tokens, { from: accounts[0] })

        console.log('Before - home.balanceOf: ', readable((await home.balanceOf(accounts[0])).toNumber()))
        console.log('Before - foreign.balanceOf: ', readable((await foreign.balanceOf(accounts[0])).toNumber()))
        console.log('Before - home.totalSupply: ', readable((await home.totalSupply()).toNumber()))
        console.log('Before - foreign.totalSupply: ', readable((await foreign.totalSupply()).toNumber()))

        // We can loop through result.logs to see if we triggered the event.
        for (var i = 0; i < enterTxn.logs.length; i++) {
            var log = enterTxn.logs[i];

            if (log.event == "EnterBridgeEvent") {
                let result = log
                let tokens = result.args.amount.toNumber()
                let fromAccount = result.args.from
                // Step 2: Validators sign transactions from bridge middleware. They are responsible for verifying
                // the home transaction tokens and originator account
                let contentHash = hashFunction(fromAccount, result.transactionHash, home.address, tokens)
                let signatures = getValidatorSignatures(contentHash)
                // Step 2.1: Bridge middleware returns signed transactionss

                // Step 3: User calls exit on foreign contract with signed transactions
                await foreign.exit(result.transactionHash, home.address, tokens, signatures, { from: accounts[0] })

                console.log('After - home.balanceOf: ', readable((await home.balanceOf(accounts[0])).toNumber()))
                console.log('After - foreign.balanceOf: ', readable((await foreign.balanceOf(accounts[0])).toNumber()))
                console.log('After - home.totalSupply: ', readable((await home.totalSupply()).toNumber()))
                console.log('After - foreign.totalSupply: ', readable((await foreign.totalSupply()).toNumber()))

                break
            }
        }

    })

    function readable(num) {
        return num / Math.pow(10, 18);
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