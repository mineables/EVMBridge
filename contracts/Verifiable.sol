pragma solidity ^0.5.0;

import './SignatureUtils.sol';
import './Ownable.sol';

/**
 * @title Verifiable
 * @dev The Verifiable contract has a set of validator addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Verifiable is Ownable, SignatureUtils {
	address[] public validators;

	modifier isVerified(bytes memory _signatures) {
		bytes32 _hash = keccak256(msg.data);
	    address[] memory recovered = recoverAddresses(_hash, _signatures);
        require(verifyValidators(recovered), "Validator verification failed.");
	    _;
	}

    function addValidator(address _validator) public onlyOwner {
        validators.push(_validator);
    }

	function verifyValidators(address[] memory _recovered) internal view returns (bool) {
		require(_recovered.length == validators.length, "Invalid number of signatures");
		for(uint i = 0 ; i < validators.length; i++) {
		    if(validators[i] != _recovered[i]) {
		        return false;
		    }
		}
		return true;
	}

}