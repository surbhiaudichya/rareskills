// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {DeleteUser} from "../../src/solidity-riddles/DeleteUser.sol";
import {AttackDeleteUser} from "../../src/solution-solidity-riddles/AttackDeleteUser.sol";

/// @title AttackDeleteUser_Test
/// @author Surbhi Audichya
contract AttackDeleteUser_Test is Test {
    DeleteUser private deleteUser;
    AttackDeleteUser private attackDeleteUser;

    address private alice = makeAddr("alice");
    address private attacker = makeAddr("attacker");

    function setUp() public {
        deleteUser = new DeleteUser();
        attackDeleteUser = new AttackDeleteUser();
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        deleteUser.deposit{value: 1 ether}();
    }

    function test_AttackDeleteUser_DrainContract() external {
        vm.startPrank(attacker);
        vm.deal(attacker, 1 ether);
        attackDeleteUser.drainDeleteUser{value: 1 ether}(deleteUser);
        assertEq(address(deleteUser).balance, 0 ether, "Challenge Incomplete");
    }
}
