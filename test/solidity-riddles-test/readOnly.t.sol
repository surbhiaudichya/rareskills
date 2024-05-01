// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {ReadOnlyPool, VulnerableDeFiContract} from "../../src/solidity-riddles/ReadOnly.sol";
import {AttackReadOnly} from "../../src/solution-solidity-riddles/AttackReadOnly.sol";

/// @title AttackReadOnly_Test
/// @author Surbhi Audichya
contract AttackReadOnly_Test is Test {
    ReadOnlyPool private readOnlyPool;
    VulnerableDeFiContract private vulnerableDeFiContract;
    AttackReadOnly private attackReadOnly;
    address private attacker = makeAddr("attacker");
    address private alice = makeAddr("alice");

    function setUp() public {
        readOnlyPool = new ReadOnlyPool();
        vulnerableDeFiContract = new VulnerableDeFiContract(readOnlyPool);
        vm.startPrank(alice);
        vm.deal(alice, 101 ether);
        readOnlyPool.addLiquidity{value: 100 ether}();
        readOnlyPool.earnProfit{value: 1 ether}();
        vulnerableDeFiContract.snapshotPrice();
        vm.stopPrank();

        vm.prank(attacker);
        attackReadOnly = new AttackReadOnly(vulnerableDeFiContract, readOnlyPool);
    }

    function test_AttackOvermint3_MintFiveNFTs() external {
        vm.startPrank(attacker);
        deal(attacker, 2 ether);
        assertEq(vulnerableDeFiContract.lpTokenPrice(), 1, "snapshotPrice");
        attackReadOnly.exploit{value: 2 ether}();
        assertEq(vulnerableDeFiContract.lpTokenPrice(), 0, "snapshotPrice should be set 0");
        assertEq(readOnlyPool.getVirtualPrice(), 1, "actully price");
    }
}
