var SignatureUtils = artifacts.require("./SignatureUtils.sol")
var Ownable = artifacts.require("./Ownable.sol")
var HomeToken = artifacts.require("./HomeToken.sol")
var ForeignToken = artifacts.require("./ForeignToken.sol")
var VerifiableTest = artifacts.require("./VerifiableTest.sol")
var NativePortal = artifacts.require("./NativePortal.sol")
var ERC20Portal = artifacts.require("./ERC20Portal.sol")
var Bitcoin = artifacts.require("./_0xBitcoinToken.sol")

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {

        console.log('network: ' + network)

        await deployer.deploy(HomeToken)
        await deployer.deploy(ForeignToken)
        await deployer.deploy(VerifiableTest)
        let bitcoin = await deployer.deploy(Bitcoin)
        let nativePortal = await deployer.deploy(NativePortal)
        let erc20Portal = await deployer.deploy(ERC20Portal, Bitcoin.address)

        if(network === 'bitchain') {
            let home = await NativePortal.deployed()
            let foreign = await ERC20Portal.deployed()
            let bitcoin = await Bitcoin.deployed()
            let bridgeUser = '0x503477fFC36343099F4EC83A066dF49EB5399629'

            await home.send(21000000 * Math.pow(10, 18), { from: accounts[1] })

            let tokensIn0xBTC = 5000 * Math.pow(10, 8)
            await bitcoin.transfer(bridgeUser, tokensIn0xBTC)

            await home.addValidator(accounts[0])
            await home.pair(foreign.address)

            await foreign.addValidator(accounts[0])
            await foreign.pair(home.address)

            console.log('bridged tokens configured')
        }

        console.log('completed deployment')

    })

};