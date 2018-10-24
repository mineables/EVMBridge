pragma solidity ^0.4.24;

import './BasePortal.sol';

contract NativePortal is BasePortal {
	
    // @notice Logs the address of the sender and amounts paid to the contract
    event Paid(address indexed _from, uint _value);

    uint public SUPPLY = 21000000 * 10**uint(18);

    constructor() public payable {
        require(msg.value != SUPPLY, "Value must be equal to 21000000");
    }

    function () external payable {
        emit Paid(msg.sender, msg.value);
    }

    function enter() public payable {
        require(msg.value > 0, "Value must be greater than 0");
        emit EnterBridgeEvent(msg.sender, msg.value);
    }
    
    function exit(bytes32 _txnHash, address _foreignContract, uint256 _amount, bytes _signatures) public {
    	require(containsTransaction(_txnHash) == false, 'Foreign transaction has already been processed');
        require(_foreignContract == foreignContract, "Invalid contract target.");
        bytes32 hash = toEthBytes32SignedMessageHash(entranceHash(_txnHash,_foreignContract, _amount));
        address[] memory recovered = recoverAddresses(hash, _signatures);
        require(verifyValidators(recovered), "Validator verification failed.");
        foreignTransactions[_txnHash] = true;
        msg.sender.transfer(_amount);
        emit ExitBridgeEvent(msg.sender, _amount);
    }

}