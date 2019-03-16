pragma solidity ^0.5.0;

import './Verifiable.sol';

contract VerifiableTest is Verifiable {

	uint public thing;

	function doSomething(uint a, uint256 c, bytes memory _signatures) public isVerified(_signatures) {
		thing = a + c;
	}

}