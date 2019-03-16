# BridgeableToken

The BridgeableToken is a super contract that defines behavior for moving ERC20 tokens from one chain to another.

Currently, there is no implemented middleware, however the signing logic and flow is defined in tests/testBridgeable.js

# Initial EVM setup

1. On Mainnet deploy the target ERC20 token (ie. 0xBitcoin) and the TokenPortal
2. On Chainnet deploy the Bridgeable Token ( ie. 0xBTC.peg ). This token represents the value proxy to the mainnet ERC20 token.
3. On Mainnet, setup validators on the TokenPortal (addValidator)
4. On Mainnet, pair the TokenPortal with the Chainnet Bridgeable Token address (pair)
5. On Chainnet, setup validators on the Bridgeable Token (addValidator)
6. On Chainnet, pair the Bridgeable Token with the Mainnet Token Portal address (pair)

# Test Environment

Ropsten is our test Mainnet and Rinkeby is our test chainnet.

Ropsten 0xBitcoin
0x576b32b5f58c3B80385f13A8479b33F881F9906d

Ropsten TokenPortal
0xFA398Cd7037B046fA7Cae20AEEe4FD00E9B35B90

Rinkeby 0xBitcoin Peg
0x6bA494Cc76636bb134BBC3eD4743Fb9b8172c8DF

# Bridge Service setup

1. Run `npm install`
2. Create an env file that contains all of your configuration. Below is an example configuration for the test environment described above.
```
# Token Portal Properties
# Token Portal Properties
PORT=4000

# Ethereum Properties
# Validator Private key - must start with 0x
PRIVATE_KEY=0x<PRIVATE_KEY_VALIDATOR>

# Bridgeable Token contract - Home is the sidechain
HOME_ETHEREUM_PROVIDER_URL=https://rinkeby.infura.io/WugAgm82bU9X5Oh2qltc 
HOME_BRIDGEABLE_CONTRACT=0x6bA494Cc76636bb134BBC3eD4743Fb9b8172c8DF

# ERC20 Portal contract - Foreign is mainnet
FOREIGN_ETHEREUM_PROVIDER_URL=https://ropsten.infura.io/WugAgm82bU9X5Oh2qltc 
FOREIGN_PORTAL_CONTRACT=0xFA398Cd7037B046fA7Cae20AEEe4FD00E9B35B90

# ERC20 - mainnet ERC20
TOKEN_CONTRACT=0x576b32b5f58c3B80385f13A8479b33F881F9906d
```
3. Start up the service with `npm index.js`

# Performing swap from 'Mainnet' to 'Chainnet'
1. Transfer 0xBitcoin to the Token Portal: bitcoin.approveAndCall(TokenPortal.address, tokens, 0x0, {from: bridgeUser})
2. Capture the transaction hash from step one and use it to build a curl command to the bridge:
    ```
    curl -d '{ "txnHash": "0x62382efda78ab186b9e30da9b4ac932b6e79cf7c208eeeebf1bfab3522638476" }' -H "Content-Type: application/json" http://127.0.0.1:4000/foreign/verify
    ```
    results:
    ```
    {
    "transactionHash": "0x62382efda78ab186b9e30da9b4ac932b6e79cf7c208eeeebf1bfab3522638476",
    "foreignContract": "0xFA398Cd7037B046fA7Cae20AEEe4FD00E9B35B90",
    "tokens": 20000000000000000000,
    "signatures": "0xdab06f2e4394fcd428e2e491470137c3036835939d0311339a9c3b89ff1f1a5f0539d26d4216fb0cb98fc8951086142c7a0823f80d018f2232dfb857657068e61c"
    }```
3. The resulting packet is a deterministic transaction that represents the value of the transfer. It can be used to store tokens completely offchain, as their value is pegged to the token bridge contract on mainnet. This packet will also only work when 'cashed in' by the same user on the side chain.
4. Complete the transfer to the Chainnet by calling the Chain's Token Peg contract's exit() method, using the parameters from the enter() transaction in the previous step
    ```
    tokenpeg.exit(transactionHash, TokenPortal.address, tokens, signatures)
    ```
    Check that your balance is now reflected in the peg contract
    ```
    tokenpeg.balanceOf(0xyour_address)
    ```

# Performing a swap from 'Chainnet' to 'Mainnet'
1. 