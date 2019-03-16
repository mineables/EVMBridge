pragma solidity ^0.5.0;

import './SignatureUtils.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract BasePortal is SignatureUtils, Ownable {
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

    function verifyValidators(address[] memory recovered) internal view returns (bool) {
        require(recovered.length == validators.length, "Invalid number of signatures");
        for(uint i = 0 ; i < validators.length; i++) {
            if(validators[i] != recovered[i]) {
                return false;
            }
        }
        return true;
    }

    function containsTransaction(bytes32 _txnHash) internal view returns (bool){
        return foreignTransactions[_txnHash];
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