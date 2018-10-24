pragma solidity ^0.4.24;

import './Verifiable.sol';

contract VerifiableTest is Verifiable {

	uint public thing;

	function doSomething(uint a, uint256 c, bytes _signatures) public isVerified(_signatures) {
		thing = a + c;
	}

}