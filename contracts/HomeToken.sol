pragma solidity ^0.5.0;

import './BridgeableToken.sol';

contract HomeToken is BridgeableToken {
    string public name = "ExampleToken1"; 
    string public symbol = "EX1";
    uint public decimals = 18;
    /*
    uint public INITIAL_SUPPLY = 10000 * (10 ** decimals);

    constructor() public {
        this._totalSupply = 0;
        //balances[msg.sender] = totalSupply_;
    }
    */
}