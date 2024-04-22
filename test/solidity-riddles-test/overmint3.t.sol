// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Overmint3} from "../../src/solidity-riddles/Overmint3.sol";
import {AttackOvermint3, Exploiter} from "../../src/solution-solidity-riddles/AttackOvermint3.sol";

/// @title AttackOvermint3_Test
/// @author Surbhi Audichya
contract AttackOvermint3_Test is Test {
    Overmint3 private overmint3;
    Exploiter private exploiter;
    address private attacker = makeAddr("attacker");

    function setUp() public {
        overmint3 = new Overmint3();
        vm.prank(attacker);
        exploiter = new Exploiter();
    }

    /// @dev It should check overmint3 mints 5 NFTs to attacker address
    function test_AttackOvermint3_MintFiveNFTs() external {
        vm.prank(attacker);
        exploiter.exploit(address(overmint3));
        assertEq(overmint3.balanceOf(attacker), 5, "Balance should be equal to five");
    }
}
