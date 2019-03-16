pragma solidity ^0.4.24;

// File: contracts/SignatureUtils.sol

/// @title A library of utilities for (multi)signatures
/// @author Alexander Kern <alex@cleargraph.com>
/// @dev This library can be linked to another Solidity contract to expose signature manipulation functions.
contract SignatureUtils {

    /// @notice Converts a bytes32 to an signed message hash.
    /// @param _msg The bytes32 message (i.e. keccak256 result) to encrypt
    function toEthBytes32SignedMessageHash(
        bytes32 _msg
    )
        pure
        public
        returns (bytes32 signHash)
    {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _msg));
    }

    /// @notice Converts a byte array to a personal signed message hash (result of `web3.personal.sign(...)`) by concatenating its length.
    /// @param _msg The bytes array to encrypt
    function toEthPersonalSignedMessageHash(
        bytes _msg
    )
        pure
        public
        returns (bytes32 signHash)
    {
        signHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uintToString(_msg.length), _msg));
    }

    /// @notice Converts a uint to its decimal string representation.
    /// @param v The uint to convert
    function uintToString(
        uint v
    )
        pure
        public
        returns (string)
    {
        uint w = v;
        bytes32 x;
        if (v == 0) {
            x = "0";
        } else {
            while (w > 0) {
                x = bytes32(uint(x) / (2 ** 8));
                x |= bytes32(((w % 10) + 48) * 2 ** (8 * 31));
                w /= 10;
            }
        }

        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory resultBytes = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            resultBytes[j] = bytesString[j];
        }

        return string(resultBytes);
    }

    /// @notice Extracts the r, s, and v parameters to `ecrecover(...)` from the signature at position `_pos` in a densely packed signatures bytes array.
    /// @dev Based on [OpenZeppelin's ECRecovery](https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ECRecovery.sol)
    /// @param _signatures The signatures bytes array
    /// @param _pos The position of the signature in the bytes array (0 indexed)
    function parseSignature(
        bytes _signatures,
        uint _pos
    )
        pure
        public
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        uint offset = _pos * 65;
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly { // solium-disable-line security/no-inline-assembly
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }

    /// @notice Counts the number of signatures in a signatures bytes array. Returns 0 if the length is invalid.
    /// @param _signatures The signatures bytes array
    /// @dev Signatures are 65 bytes long and are densely packed.
    function countSignatures(
        bytes _signatures
    )
        pure
        public
        returns (uint)
    {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }

    /// @notice Recovers an address using a message hash and a signature in a bytes array.
    /// @param _hash The signed message hash
    /// @param _signatures The signatures bytes array
    /// @param _pos The signature's position in the bytes array (0 indexed)
    function recoverAddress(
        bytes32 _hash,
        bytes _signatures,
        uint _pos
    )
        pure
        public
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = parseSignature(_signatures, _pos);
        return ecrecover(_hash, v, r, s);
    }

    /// @notice Recovers an array of addresses using a message hash and a signatures bytes array.
    /// @param _hash The signed message hash
    /// @param _signatures The signatures bytes array
    function recoverAddresses(
        bytes32 _hash,
        bytes _signatures
    )
        pure
        public
        returns (address[] addresses)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/BasePortal.sol

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

    function verifyValidators(address[] recovered) internal view returns (bool) {
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

// File: contracts/ERC20Interface.sol

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);
}

// File: contracts/ERC20Portal.sol

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20Portal is BasePortal {

    address public tokenAddress;

    // don't accept any Ether
    function () public payable {
        revert();
    }

    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    // single step option for tokens that have implemented approveAndCall
    function receiveApproval(address from, uint256 tokens, address token, bytes /* data */) public {
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
