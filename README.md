# EVM Bridge

The EVM Bridge contains EVM *Portal* smart contracts and decentralized middleware for safely transporting Ether and ERC20 tokens to/from EVMs.

Currently, the middleware is in a beta state, however the signing logic and flow is well defined in tests/testBridgeable.js

# Design

Conceptually there are really 2 *Portal* smart contracts of concern:
    * NativePortal - a gateway to an EVM's native token (ie. Ether)
    * ERC20Portal - a gateway to an ERC20 compliant Token.
```    
          +-------------+       +----------------+       +--------------+
          |             +------>+                +------>+              |
          | ERC20Portal |       | Bridge Network |       | NativePortal |
          |             +<------+                +<------+              |
+-------+ +-------------+       +----------------+       +--------------+ +--------+
| 0xBTC |  EVM1 (Mainnet)                               EVM2 (0xBitchain) | "Ether"|
+-------+                                                                 +--------+
```

The System uses these *Portal* contracts, responsible for registering/deregistering validators, and confirming signed transfer requests from users. Validators listen for portal requests from Portal contract entry events and confirm/drop transactions accordingly.

## ERC20 -> Native EVM
An example scenario might be user Alice wishes to transfer 100 0xBitcoin over to the xDAI network in order to pay for services within that environment. The EVM Bridge stack would follow these steps (see test/testERC20ToNative.js):

0. Setup: Validators register their address with each Portal contract and initial deployer pairs the addresses of the token contract addresses. This operation can only be performed once during setup to ensure decentralization.
1. The bridge user calls ERC20.approveAndCall() to the ERC20Portal with the 100 0xBitcoin Tokens requested.
2. The approveAndCall() locks the 100 0xBTC into the contract and causes the ERCPortal to emit an *EnterBridgeEvent* containing the amount of tokens to transfer across the bridge.
3. The Bridge Network approves and signs the transaction. Once all members have signed the transaction, it is returned to the bridge user.
4. The bridge user submits the verified transaction to the Native Portal contract on the destination EVM.
5. The NativePortal contract sends 100 "Ether" ( not actually Ether, but the native token on the destination EVM ), which is a 1:1 tether to the 0xBitcoin Token on mainnet.
6. In reverse, when the user wants to send the funds back to mainnet, she simply calls the NativePortal first, waits for validation from the bridge network and then calls the ERCPortal which will release the tokens from the contract.

## ERC20 -> ERC20
```
          +-------------+       +----------------+       +--------------+
          |             +------>+                +------>+              |
          | ERC20Portal |       | Bridge Network |       |  ERC20Portal |
          |             +<------+                +<------+              |
+-------+ +-------------+       +----------------+       +--------------++-----------+
| 0xBTC |                                                                | 0xBTC.PEG |
+-------+                                                                +-----------+
```

Transferring value from ERC20 on mainnet to ERC20 on chainnet follows a similar set of steps, except on the chainnet side, ERC20 "Peg" tokens are minted/burned as they enter and exit the EVM.

# Initial EVM setup

1. On Mainnet deploy the target ERC20 token (ie. 0xBitcoin) and the TokenPortal
2. On Chainnet deploy the Bridgeable Token ( ie. 0xBTC.peg ). This token represents the value proxy to the mainnet ERC20 token.
3. On Mainnet, setup validators on the TokenPortal (addValidator)
4. On Mainnet, pair the TokenPortal with the Chainnet Bridgeable Token address (pair)
5. On Chainnet, setup validators on the Bridgeable Token (addValidator)
6. On Chainnet, pair the Bridgeable Token with the Mainnet Token Portal address (pair)

# Test Environment

As an example, Ropsten is our test Mainnet and Rinkeby is our test chainnet.

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

* Note: Since the state of these transactions is stored 100% between the chains, you can call http://127.0.0.1:4000/transactions/0xYOUR-ADDRESS anytime to get a complete view of the bridge's transactions.

1. Transfer 0xBitcoin to the Token Portal: bitcoin.approveAndCall(TokenPortal.address, tokens, 0x0)
2. Capture the transaction hash from step one and use it to build a 'foreign/verify' curl command to the bridge:
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
    }
    ```
    The resulting packet is a deterministic transaction that represents the value of the transfer. It can be used to store tokens completely offchain, as their value is pegged to the token bridge contract on mainnet. This packet will also only work when 'cashed in' by the same user on the side chain.
3. Complete the transfer to the Chainnet by calling the Chain's Token Peg contract's exit() method, using the parameters from the enter() transaction in the previous step
    ```
    tokenpeg.exit(transactionHash, TokenPortal.address, tokens, signatures)
    ```
    Check that your balance is now reflected in the peg contract
    ```
    tokenpeg.balanceOf(0xyour_address)
    ```

# Performing a swap from 'Chainnet' to 'Mainnet'
1. Enter the bridge from the chainnet side: tokenpeg.enter(tokens)
2. Capture the transaction hash from the previous step and use it to build a 'home/verify' curl command to the bridge
    ```
    curl -d '{ "txnHash": "0x008cb7525740933c82819aa5c79bcfb05a479af547138a0a0f9c67a7282e1354" }' -H "Content-Type: application/json" http://127.0.0.1:4000/home/verify
    
    ```
    results:
    ```
    {
        "transactionHash": "0x008cb7525740933c82819aa5c79bcfb05a479af547138a0a0f9c67a7282e1354",
        "foreignContract": "0x6bA494Cc76636bb134BBC3eD4743Fb9b8172c8DF",
        "tokens": 1000000000,
        "signatures": "0xf78bd31638000165943e943ce54b59874d9d53d4f35b3f0f2c4da1207265cc142ff2c84a8f72be983f4e6e3c00a3ebe0113f8953319d9f392c7d51f72197b0bd1b"
    }
    ```
3. Complete the transfer to Mainnet by calling the chain's Portal contract's exit() method, using the parameters from the enter() transaction in the previous step.
    ```
    portal.exit(transactionHash, PegToken.address, tokens, signatures)
    ```
    Check that your balance is now reflected in the target mainnet token contract
    ```
    erc20.balanceOf(0xyour_address)
    ```
