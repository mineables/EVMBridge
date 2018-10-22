pragma solidity ^0.4.24;

import './Bridgeable.sol';

contract ForeignToken is Bridgeable {
    string public name = "ExampleToken"; 
    string public symbol = "FIX";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 10000 * (10 ** decimals);

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY / 2;
        balances[msg.sender] = totalSupply_;
    }
}