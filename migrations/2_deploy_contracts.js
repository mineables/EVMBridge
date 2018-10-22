var SignatureUtils = artifacts.require("./SignatureUtils.sol")
var Ownable = artifacts.require("./Ownable.sol")
var HomeToken = artifacts.require("./HomeToken.sol")
var ForeignToken = artifacts.require("./ForeignToken.sol")

module.exports = function (deployer, network, accounts) {

  deployer.then(async () => {

    console.log('network: ' + network)
    
    let home = await deployer.deploy(HomeToken)
    let foreign = await deployer.deploy(ForeignToken)

    console.log('completed deployment')

  })

};
