// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Contratto {
    uint public x;
    uint public y;

    constructor() {
        x = 5;
        y = 10;
    }

    function setX(uint _x) public {
        x = _x;
    }

    function setY(uint _y) public {
        y = _y;
    }

    /// @custom:invariant
    function inv_xy() public view {
        assert(x + y == 15);
    }
}
