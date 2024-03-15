// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Overmint1} from "../../src/solidity-riddles/Overmint1.sol";

import {AttackOvermint1} from "../../src/solution-solidity-riddles/AttackOvermint1.sol";

/// @title AttackOvermint1_Test
/// @author Surbhi Audichya
contract AttackOvermint1_Test is Test {
    Overmint1 private overmint1;
    AttackOvermint1 private attackOvermint1;
    address private attacker = makeAddr("attacker");

    function setUp() public {
        overmint1 = new Overmint1();
        vm.prank(attacker);
        attackOvermint1 = new AttackOvermint1(address(overmint1));
    }

    /// @dev It should mint 5 overmint1 NFTs to attacker address
    function test_AttackOvermint1_MintFiveNFTs() external {
        vm.prank(attacker);
        attackOvermint1.exploitOvermint1();
        assertTrue(overmint1.success(attacker), "Balance should be equal to five");
    }
}
