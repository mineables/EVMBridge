var HomeToken = artifacts.require("./HomeToken.sol")
var ForeignToken = artifacts.require("./ForeignToken.sol")
var NativePortal = artifacts.require("./NativePortal.sol")
var ERC20Portal = artifacts.require("./ERC20Portal.sol")
var Bitcoin = artifacts.require("./_0xBitcoinToken.sol")

module.exports = function(deployer, network, accounts) {

    deployer.then(async () => {

        console.log('network: ' + network)

        await deployer.deploy(HomeToken)
        //await deployer.deploy(ForeignToken)
        //await deployer.deploy(NativePortal)
        await deployer.deploy(Bitcoin)
        await deployer.deploy(ERC20Portal, Bitcoin.address)

        console.log('completed deployment')

    })

};