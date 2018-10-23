pragma solidity ^0.4.24;

import './SignatureUtils.sol';
import './Ownable.sol';
import './ERC20Interface.sol';

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20Bridge is ApproveAndCallFallBack, SignatureUtils, Ownable {
	address[] public validators;
	address public foreignContract;
	mapping (bytes32 => bool) foreignTransactions;
    address public tokenAddress;

	event EnterBridgeEvent(address from, uint256 amount);
    event ExitBridgeEvent(address sender, uint256 amount);
    event Mint(address indexed to, uint256 amount);
	event Burn(address indexed burner, uint256 value);

    // don't accept any Ether
    function () public payable {
        revert();
    }

    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    function addValidator(address _validator) public onlyOwner {
        validators.push(_validator);
    }

    function pair(address _foreignContract) public onlyOwner {
    	foreignContract = _foreignContract;
    }

    // single step option for tokens that have implemented approveAndCall
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public {
        require(tokens > 0, "Value must be greater than 0");
        require(tokenAddress == token, "Target Token Address is invalid.");
        require(ERC20Interface(tokenAddress).transferFrom(from, address(this), tokens), "Could not transfer tokens");
        emit EnterBridgeEvent(from, tokens);
    }
    
    // two step operation that requires a previous call to approve
    function enter(uint _amount) public {
        receiveApproval(msg.sender, _amount, tokenAddress, '');
    }
    
    function exit(bytes32 _txnHash, address _foreignContract, uint256 _amount, bytes _signatures) public {
    	require(contains(_txnHash) == false, 'Foreign transaction has already been processed');
        require(_foreignContract == foreignContract, "Invalid contract target.");
        bytes32 hash = toEthBytes32SignedMessageHash(entranceHash(_txnHash,_foreignContract, _amount));
        address[] memory recovered = recoverAddresses(hash, _signatures);
        require(verifyValidators(recovered), "Validator verification failed.");
        foreignTransactions[_txnHash] = true;
        require(ERC20Interface(tokenAddress).transfer(msg.sender, _amount), "Could not transfer tokens");
        emit ExitBridgeEvent(msg.sender, _amount);
    }

    function contains(bytes32 _txnHash) internal view returns (bool){
        return foreignTransactions[_txnHash];
    }

    function verifyValidators(address[] recovered) internal view returns (bool) {
        require(recovered.length == validators.length, "Invalid number of signatures");
        for(uint i = 0 ; i < validators.length; i++) {
            if(validators[i] != recovered[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Hash (keccak256) of the payload used by deposit
     * @param _contractAddress the target ERC20 address
     * @param _amount the original minter
     */
    function entranceHash(bytes32 txnHash, address _contractAddress, uint256 _amount) public view returns (bytes32) {
        // "0x8177cf3c": entranceHash(bytes32, address,uint256)
        return keccak256(abi.encode( bytes4(0x8177cf3c), msg.sender, txnHash, _contractAddress, _amount));
    }

}