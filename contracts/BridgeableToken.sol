pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol';
import './SignatureUtils.sol';
import './Ownable.sol';

contract BridgeableToken is ERC20Mintable, SignatureUtils, Ownable {
	address[] public validators;
	address public foreignContract;
	mapping (bytes32 => bool) foreignTransactions;

	event EnterBridgeEvent(address from, uint256 amount);
    event ExitBridgeEvent(address sender, uint256 amount);
    event Mint(address indexed to, uint256 amount);
	event Burn(address indexed burner, uint256 value);

    function addValidator(address _validator) public onlyOwner {
        validators.push(_validator);
    }

    function pair(address _foreignContract) public onlyOwner {
    	foreignContract = _foreignContract;
    }
        
    function enter(uint256 _amount) public {
        emit EnterBridgeEvent(msg.sender, _amount);
        burn(_amount);
    }
    
    function exit(bytes32 _txnHash, address _foreignContract, uint256 _amount, bytes memory _signatures) public {
    	require(contains(_txnHash) == false, 'Foreign transaction has already been processed');
        bytes32 hash = toEthBytes32SignedMessageHash(entranceHash(_txnHash,_foreignContract, _amount));
        address[] memory recovered = recoverAddresses(hash, _signatures);
        require(verifyValidators(recovered), "Validator verification failed.");
        require(_foreignContract == foreignContract, "Invalid contract target.");
        mint(msg.sender, _amount);
        foreignTransactions[_txnHash] = true;
        emit ExitBridgeEvent(msg.sender, _amount);      
    }

    function contains(bytes32 _txnHash) internal view returns (bool){
        return foreignTransactions[_txnHash];
    }

    function verifyValidators(address[] memory recovered) internal view returns (bool) {
        require(recovered.length == validators.length, "Invalid number of signatures");
        for(uint i = 0 ; i < validators.length; i++) {
            if(validators[i] != recovered[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The account whose tokens will be burned.
     * @param value uint256 The amount of token to be burned.
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
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