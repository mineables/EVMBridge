pragma solidity ^0.4.24;

import './SignatureUtils.sol';
import './Ownable.sol';

contract NativeBridge is SignatureUtils, Ownable {
	address[] public validators;
	address public foreignContract;
	mapping (bytes32 => bool) foreignTransactions;

	event EnterBridgeEvent(address from, uint256 amount);
    event ExitBridgeEvent(address sender, uint256 amount);
    event Mint(address indexed to, uint256 amount);
	event Burn(address indexed burner, uint256 value);

    /// @notice Logs the address of the sender and amounts paid to the contract
    event Paid(address indexed _from, uint _value);

    uint public SUPPLY = 21000000 * 10**uint(18);

    constructor() public payable {
        require(msg.value != SUPPLY, "Value must be equal to 21000000");
    }

    function () external payable {
        Paid(msg.sender, msg.value);
    }

    function addValidator(address _validator) public onlyOwner {
        validators.push(_validator);
    }

    function pair(address _foreignContract) public onlyOwner {
    	foreignContract = _foreignContract;
    }
    
    function enter() public payable {
        require(msg.value > 0, "Value must be greater than 0");
        emit EnterBridgeEvent(msg.sender, msg.value);
    }
    
    function exit(bytes32 _txnHash, address _foreignContract, uint256 _amount, bytes _signatures) public {
    	require(contains(_txnHash) == false, 'Foreign transaction has already been processed');
        require(_foreignContract == foreignContract, "Invalid contract target.");
        bytes32 hash = toEthBytes32SignedMessageHash(entranceHash(_txnHash,_foreignContract, _amount));
        address[] memory recovered = recoverAddresses(hash, _signatures);
        require(verifyValidators(recovered), "Validator verification failed.");
        foreignTransactions[_txnHash] = true;
        msg.sender.send(_amount);
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