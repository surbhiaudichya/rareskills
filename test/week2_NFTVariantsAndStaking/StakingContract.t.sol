// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.6.0 < 0.9.0;

import {
    StakingContract, RewardToken
} from "../../src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/StakingContract.sol";
import {MerkleWhitelistNFT} from "../../src/week2_NFTVariantsAndStaking/NFTStakingEcosystem/MerkleWhitelistNFT.sol";
import {MerkleWhitelistNFTTest} from "./MerkleWhitelistNFT.t.sol";
import "forge-std/console.sol";

contract StakingContractTest is MerkleWhitelistNFTTest {
    StakingContract private stakingContract;

    event RewardsClaimed(address indexed user, uint256 rewardToMint);

    function setUp() public override {
        super.setUp();
        stakingContract = new StakingContract(address(nft));
    }

    function setUpMintNFTToUser(address user, uint256 tokenId) internal {
        vm.startPrank(user);
        nft.mint{value: 0.5 ether}(tokenId);
    }

    function test_Stake(uint256 tokenId) public {
        vm.assume(tokenId < 1000);
        setUpMintNFTToUser(userA, tokenId);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), tokenId);
        assertEq(nft.ownerOf(tokenId), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);
    }

    function test_Withdraw(uint256 tokenId) public {
        vm.assume(tokenId < 1000);
        setUpMintNFTToUser(userA, tokenId);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), tokenId);
        assertEq(nft.ownerOf(tokenId), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Withdraw after 12 hours
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 5e18);
        stakingContract.withdraw(tokenId);
        assertEq(nft.ownerOf(tokenId), userA);
    }

    function test_Stake_Withdraw_MultipleTimes(uint256 tokenId) public {
        // stake
        vm.assume(tokenId < 1000);
        setUpMintNFTToUser(userA, tokenId);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), tokenId);
        assertEq(nft.ownerOf(tokenId), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Withdraw after 12 hours
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 5e18);
        stakingContract.withdraw(tokenId);
        assertEq(nft.ownerOf(tokenId), userA);

        // stake after 12 hours
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), tokenId);
        assertEq(nft.ownerOf(tokenId), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Withdraw after 12 hours
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 5e18);
        stakingContract.withdraw(tokenId);
        assertEq(nft.ownerOf(tokenId), userA);
    }

    function test_StakeMultipleUser(uint256 tokenIdA, uint256 tokenIdB) public {
        vm.assume(tokenIdA != tokenIdB);
        setUpMintNFTToUser(userA, tokenIdA);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), tokenIdA);
        assertEq(nft.ownerOf(tokenIdA), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        skip(12 hours);
        setUpMintNFTToUser(userB, tokenIdB);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userB, 0);
        nft.safeTransferFrom(userB, address(stakingContract), tokenIdB);
        assertEq(nft.ownerOf(tokenIdB), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);
    }

    function test_WithdrawMultipleUser(uint256 tokenIdA, uint256 tokenIdB) public {
        vm.assume(tokenIdA != tokenIdB);
        setUpMintNFTToUser(userA, tokenIdA);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), tokenIdA);
        assertEq(nft.ownerOf(tokenIdA), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        skip(12 hours);
        setUpMintNFTToUser(userB, tokenIdB);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userB, 0);
        nft.safeTransferFrom(userB, address(stakingContract), tokenIdB);
        assertEq(nft.ownerOf(tokenIdB), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        skip(12 hours);
        vm.startPrank(userA);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 10e18);
        stakingContract.withdraw(tokenIdA);
        assertEq(nft.ownerOf(tokenIdA), userA);

        skip(12 hours);
        vm.startPrank(userB);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userB, 10e18);
        stakingContract.withdraw(tokenIdB);
        assertEq(nft.ownerOf(tokenIdB), userB);
    }
}
