// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Denial} from "../../src/solidity-riddles/Denial.sol";

import {AttackDenial} from "../../src/solution-solidity-riddles/AttackDenial.sol";

/// @title AttackOvermint1_Test
/// @author Surbhi Audichya
contract AttackDenial_Test is Test {
    Denial private denial;
    AttackDenial private attackDenial;
    address private attacker = makeAddr("attacker");

    function setUp() public {
        denial = new Denial();
        vm.prank(attacker);
        attackDenial = new AttackDenial();
        denial.setWithdrawPartner(address(attackDenial));
        deal(address(denial), 100 ether);
    }

    /// @dev Owner should not be able to call withdraw
    function test_AttackDenial() external {
        // Message-less reverts happen when there is an EVM error, such as when the transaction consumes more than the block’s gas limit.
        vm.expectRevert(bytes(""));
        denial.withdraw{gas: 1000000}();
    }
}
