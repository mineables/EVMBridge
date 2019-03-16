pragma solidity ^0.5.0;

import './BasePortal.sol';
import './ERC20Interface.sol';

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract ERC20Portal is BasePortal {

    address public tokenAddress;

    // don't accept any Ether
    function () external payable {
        revert();
    }

    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    // single step option for tokens that have implemented approveAndCall
    function receiveApproval(address from, uint256 tokens, address token, bytes memory/* data */) public {
        require(tokens > 0, "Value must be greater than 0");
        require(tokenAddress == token, "Target Token Address is invalid.");
        require(ERC20Interface(tokenAddress).transferFrom(from, address(this), tokens), "Could not transfer tokens");
        emit EnterBridgeEvent(from, tokens);
    }
    
    // two step operation that requires a previous call to approve
    function enter(uint _amount) public {
        receiveApproval(msg.sender, _amount, tokenAddress, '');
    }
    
    function exit(bytes32 _txnHash, address _foreignContract, uint256 _amount, bytes memory _signatures) public {
    	require(containsTransaction(_txnHash) == false, 'Foreign transaction has already been processed');
        require(_foreignContract == foreignContract, "Invalid contract target.");
        bytes32 hash = toEthBytes32SignedMessageHash(entranceHash(_txnHash,_foreignContract, _amount));
        address[] memory recovered = recoverAddresses(hash, _signatures);
        require(verifyValidators(recovered), "Validator verification failed.");
        foreignTransactions[_txnHash] = true;
        require(ERC20Interface(tokenAddress).transfer(msg.sender, _amount), "Could not transfer tokens");
        emit ExitBridgeEvent(msg.sender, _amount);
    }
}