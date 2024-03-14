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

    function test_StakeMultipleTimes() public {
        setUpMintNFTToUser(userA, 2);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), 2);
        assertEq(nft.ownerOf(2), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward for stking one NFT for 12 hours
        skip(12 hours);
        setUpMintNFTToUser(userA, 3);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 5e18);
        nft.safeTransferFrom(userA, address(stakingContract), 3);
        assertEq(nft.ownerOf(3), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward for stking two NFT for 12 hours
        skip(12 hours);
        setUpMintNFTToUser(userA, 4);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 10e18);
        nft.safeTransferFrom(userA, address(stakingContract), 4);
        assertEq(nft.ownerOf(4), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward for stking three NFT for 12 hours
        skip(12 hours);
        setUpMintNFTToUser(userA, 5);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 15e18);
        nft.safeTransferFrom(userA, address(stakingContract), 5);
        assertEq(nft.ownerOf(5), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);
    }

    function test_StakeMultipleTimesMultipleUsers() public {
        // UerA: TotalBalance = 1 , AccRewardPerToken = 0, Reward = oldTotalBalance * AccRewardPerToke - debt , Debt = NewTotalBalance * AccRewardPerToken = 1 * 0 = 0
        setUpMintNFTToUser(userA, 2);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), 2);
        assertEq(nft.ownerOf(2), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        //UserB: TotalBalance = 1 , AccRewardPerToken = 5, Reward = 0 * 5 - 0, Debt = 1 * 5
        skip(12 hours);
        setUpMintNFTToUser(userB, 3);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userB, 0);
        nft.safeTransferFrom(userB, address(stakingContract), 3);
        assertEq(nft.ownerOf(3), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // UserA: TotalBalance = 2 , AccRewardPerToken = 10, Reward = 1*10 - 0, update debt = 2 * 10 = 20
        skip(12 hours);
        setUpMintNFTToUser(userA, 4);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 10e18);
        nft.safeTransferFrom(userA, address(stakingContract), 4);
        assertEq(nft.ownerOf(4), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // UserB: TotalBalance = 2 , Debt = 5 , AccRewardPerToken = 15, Reward = 1(15) - 5 = 10, updated Debt = 2 * 15 = 30
        skip(12 hours);
        setUpMintNFTToUser(userB, 5);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userB, 10e18);
        nft.safeTransferFrom(userB, address(stakingContract), 5);
        assertEq(nft.ownerOf(5), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // UserA: TotalBalance = 3 , Debt = 30, AccRewardPerToken = 20, Reward = 2*20 - 20 = 20, new debt = 3 * 20 = 60
        skip(12 hours);
        setUpMintNFTToUser(userA, 6);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 20e18);
        nft.safeTransferFrom(userA, address(stakingContract), 6);
        assertEq(nft.ownerOf(6), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // UserB: TotalBalance = 3 , Debt = 30 , AccRewardPerToken = 25, Reward = 2(25) - 30 = 20, updated Debt = 3 * 25 = 75
        skip(12 hours);
        setUpMintNFTToUser(userB, 7);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userB, 20e18);
        nft.safeTransferFrom(userB, address(stakingContract), 7);
        assertEq(nft.ownerOf(7), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // UserA: TotalBalance = 4 , Debt = 60, AccRewardPerToken = 30, Reward = 3*30 - 60 = 30, new debt = 4 * 30 = 120
        skip(12 hours);
        setUpMintNFTToUser(userA, 8);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 30e18);
        nft.safeTransferFrom(userA, address(stakingContract), 8);
        assertEq(nft.ownerOf(8), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);
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
        // Stake
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

    function test_WithdrawMultipleTimes() public {
        // AccReward = 0 , rewardToMint = 0 , debt = 0
        setUpMintNFTToUser(userA, 2);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 0);
        nft.safeTransferFrom(userA, address(stakingContract), 2);
        assertEq(nft.ownerOf(2), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward for satking one NFT for 12 hours
        // AccReward = 5 , rewardToMint = 5 , debt = 2 * 5 = 10
        skip(12 hours);
        setUpMintNFTToUser(userA, 3);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 5e18);
        nft.safeTransferFrom(userA, address(stakingContract), 3);
        assertEq(nft.ownerOf(3), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward for satking two NFT for 12 hours
        // AccReward = 10 , rewardToMint = 2 * 10 - 10 = 10  , debt = 3 * 10 = 30
        skip(12 hours);
        setUpMintNFTToUser(userA, 4);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 10e18);
        nft.safeTransferFrom(userA, address(stakingContract), 4);
        assertEq(nft.ownerOf(4), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward for staking three NFT for 12 hours
        // AccReward = 15 , rewardToMint = 3 * 15 - 30 = 15  , debt = 4 * 15 = 60
        skip(12 hours);
        setUpMintNFTToUser(userA, 5);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 15e18);
        nft.safeTransferFrom(userA, address(stakingContract), 5);
        assertEq(nft.ownerOf(5), address(stakingContract));
        assertEq(stakingContract.lastRewardTimestamp(), block.timestamp);

        // Reward when withdrawing one NFT after 12 hours. 4 NFT in contract
        // AccReward = 20, rewardToMint = 4 * 20 - 60 = 20  , debt = 3 * 20 = 60
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 20e18);
        stakingContract.withdraw(5);
        assertEq(nft.ownerOf(5), userA);

        // Reward when withdrawing one NFT after 12 hours. 3 NFT in contract
        // AccReward = 25, rewardToMint = 3 * 25 - 60 = 16  , debt = 2 * 25 = 50
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 15e18);
        stakingContract.withdraw(4);
        assertEq(nft.ownerOf(4), userA);

        // Reward when withdrawing one NFT after 12 hours. 2 NFT in contract
        // AccReward = 30, rewardToMint = 2 * 30 - 50 = 10  , debt = 1 * 30 = 30
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 10e18);
        stakingContract.withdraw(3);
        assertEq(nft.ownerOf(3), userA);

        // Reward when withdrawing one NFT after 12 hours. 1 NFT in contract
        // AccReward = 35, rewardToMint = 1 * 35 - 30 = 5  , debt = 0 * 35 = 0
        skip(12 hours);
        vm.expectEmit(true, false, false, true);
        emit RewardsClaimed(userA, 5e18);
        stakingContract.withdraw(2);
        assertEq(nft.ownerOf(2), userA);
    }
}
