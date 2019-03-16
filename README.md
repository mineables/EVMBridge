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

# Bridge Service setup

1. Run `npm install`
2. Create an env file that contains all of your configuration
```
# Token Portal Properties
PORT=4000

# Ethereum Properties
PRIVATE_KEY=0xPrivateKey

# Bridgeable Token contract - Home is the sidechain
HOME_ETHEREUM_PROVIDER_URL=<home-provider-url>
HOME_BRIDGEABLE_CONTRACT=<0xBridgeableTokenContract>

# ERC20 Portal contract - Foreign is mainnet
FOREIGN_ETHEREUM_PROVIDER_URL=<foreign-provider-url>
FOREIGN_PORTAL_CONTRACT=<0xBridgePortalERC20Contract>

# ERC20 - mainnet ERC20
TOKEN_CONTRACT=<mainnet-ERC20-address>
```
3. Start up the service with `npm index.js`