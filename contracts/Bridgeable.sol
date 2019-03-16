pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './SignatureUtils.sol';

contract Bridgeable is StandardToken, SignatureUtils, Ownable {
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
    
    function exit(bytes32 _txnHash, address _foreignContract, uint256 _amount, bytes _signatures) public {
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

    function verifyValidators(address[] recovered) internal view returns (bool) {
        require(recovered.length == validators.length, "Invalid number of signatures");
        for(uint i = 0 ; i < validators.length; i++) {
            if(validators[i] != recovered[i]) {
                return false;
            }
        }
        return true;
    }

    function mint( address _to, uint256 _amount )
	    internal returns (bool) {
	    totalSupply_ = totalSupply_.add(_amount);
	    balances[_to] = balances[_to].add(_amount);
	    emit Mint(_to, _amount);
	    emit Transfer(address(0), _to, _amount);
	    return true;
	}

	/**
	* @dev Burns a specific amount of tokens.
	* @param _value The amount of token to be burned.
	*/
	function burn(uint256 _value) internal {
		_burn(msg.sender, _value);
	}

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		// no need to require value <= totalSupply, since that would imply the
		// sender's balance is greater than the totalSupply, which *should* be an assertion failure

		balances[_who] = balances[_who].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
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