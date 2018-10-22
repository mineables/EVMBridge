
pragma solidity ^0.4.24;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Invalid requirement c >= a [ SafeMath.add() ]");
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Invalid requirement b <= a [ SafeMath.sub() ]");
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Invalid requirement a == 0 || c / a == b [ SafeMath.mul() ]");
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Invalid requirement b > 0 [ SafeMath.div() ]");
        c = a / b;
    }

}
