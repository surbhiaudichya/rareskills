// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Overmint1_ERC1155} from "../../src/solidity-riddles/Overmint1-ERC1155.sol";

import {AttackOvermint1_ERC1155} from "../../src/solution-solidity-riddles/AttackOvermint1-ERC1155.sol";

/// @title AttackOvermint1_Test
/// @author Surbhi Audichya
contract AttackOvermint1_ERC1155_Test is Test {
    Overmint1_ERC1155 private overmint1155;
    AttackOvermint1_ERC1155 private attackOvermint1155;
    address private attacker = makeAddr("attacker");

    function setUp() public {
        overmint1155 = new Overmint1_ERC1155();
        vm.prank(attacker);
        attackOvermint1155 = new AttackOvermint1_ERC1155(address(overmint1155));
    }

    /// @dev It should mint 5 overmint1 NFTs to attacker address
    function test_AttackOvermint1_ERC1155_MintFiveNFTs() external {
        vm.prank(attacker);
        attackOvermint1155.exploitOvermint1155();
        assertTrue(overmint1155.success(attacker, 1), "Balance should be equal to five");
    }
}
