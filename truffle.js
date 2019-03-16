require('dotenv').config()
var Web3 = require('web3')
const HDWalletProvider = require("truffle-hdwallet-provider")

module.exports = {
	networks: {
	
	  	sokol: {
	      provider: function() {
	        return new HDWalletProvider(process.env.MNEMONIC, "https://sokol.poa.network")
	      },
	      network_id: 3,
	      gas: 7000000,
	      gasPrice: 1000000000
	 	},
	 	bitchain: {
	      host: "68.183.26.29",
	      port: 8547,
	      network_id: "*",
	      from: "0x2b833b6ae9a5f46667c923f9509e0389c1f4c367",
	      //gas: 10000000,
	      gasPrice: 1
	    },

	},

	compilers: {
			solc: {
				version: "0.5.6"
			}
	}
};
