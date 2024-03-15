// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Overmint2} from "../../src/solidity-riddles/Overmint2.sol";
import {AttackOvermint2} from "../../src/solution-solidity-riddles/AttackOvermint2.sol";

/// @title AttackOvermint2_Test
/// @author Surbhi Audichya
contract AttackOvermint2_Test is Test {
    Overmint2 private overmint2;
    AttackOvermint2 private attackOvermint2;
    address private attacker = makeAddr("attacker");

    function setUp() public {
        overmint2 = new Overmint2();
        vm.prank(attacker);
        attackOvermint2 = new AttackOvermint2(address(overmint2));
    }

    /// @dev It should mint 5 overmint1 NFTs to attacker address
    function test_AttackOvermint1_MintFiveNFTs() external {
        vm.prank(attacker);
        attackOvermint2.exploitOvermint2();
        assertTrue(overmint2.success(), "Balance should be equal to five");
    }
}
