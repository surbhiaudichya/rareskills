// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.9.0;

import {Test} from "forge-std/Test.sol";
import {RewardToken, NftToStake, Depositoor} from "../../src/solidity-riddles/RewardToken.sol";
import {AttackRewardToken} from "../../src/solution-solidity-riddles/AttackRewardToken.sol";

/// @title AttackRewardToken_Test
/// @author Surbhi Audichya
contract AttackRewardToken_Test is Test {
    Depositoor public depositor;
    NftToStake public nft;
    RewardToken private rewardToken;
    AttackRewardToken private attackRewardToken;
    address private attacker = makeAddr("attacker");

    function setUp() public {
        attackRewardToken = new AttackRewardToken();
        nft = new NftToStake(address(attackRewardToken));
        depositor = new Depositoor(nft);
        rewardToken = new RewardToken(address(depositor));
        depositor.setRewardToken(rewardToken);
    }

    function test_AttackOvermint3_MintFiveNFTs() external {
        vm.startPrank(attacker);
        attackRewardToken.stake(nft, depositor, 42);
        vm.warp(10 days);
        attackRewardToken.drain(rewardToken, 42);
        assertEq(rewardToken.balanceOf(address(attacker)), 100 ether);
        assertEq(rewardToken.balanceOf(address(depositor)), 0);
    }
}
