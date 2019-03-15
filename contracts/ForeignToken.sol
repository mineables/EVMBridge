pragma solidity ^0.4.24;

import './BridgeableToken.sol';

contract ForeignToken is BridgeableToken {
    string public name = "ExampleToken2"; 
    string public symbol = "EX2";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 10000 * (10 ** decimals);

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY / 2;
        balances[msg.sender] = totalSupply_;
    }
}