var SignatureUtils = artifacts.require("./SignatureUtils.sol")
var Ownable = artifacts.require("./Ownable.sol")
var HomeToken = artifacts.require("./HomeToken.sol")
var ForeignToken = artifacts.require("./ForeignToken.sol")
var VerifiableTest = artifacts.require("./VerifiableTest.sol")
var NativeBridge = artifacts.require("./NativeBridge.sol")
var ERC20Bridge = artifacts.require("./ERC20Bridge.sol")
var Bitcoin = artifacts.require("./_0xBitcoinToken.sol")

module.exports = function (deployer, network, accounts) {

  deployer.then(async () => {

    console.log('network: ' + network)
    
    await deployer.deploy(HomeToken)
    await deployer.deploy(ForeignToken)
    await deployer.deploy(VerifiableTest)
    await deployer.deploy(NativeBridge)
    await deployer.deploy(Bitcoin)
    await deployer.deploy(ERC20Bridge, Bitcoin.address)

    console.log('completed deployment')

  })

};
