// SPDX-License-Identifier: MIT
/**
 * @title StackingContract
 * @dev Stacking Contract that can mint new ERC20 tokens and receive ERC721 tokens.
 * Users can send their NFTs and withdraw 10 ERC20 tokens every 24 hours
 */
pragma solidity >= 0.6.0 < 0.9.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721, IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {RewardToken} from "./RewardToken.sol";

contract StakingContract is IERC721Receiver {
    // Address of the ERC721 token contract
    address nft;
    // Instance of the RewardToken contract
    RewardToken public immutable rewardToken;
    // Amount of reward tokens to distribute per 24 hours
    uint256 rewardPer24Hours = 10e18;
    // Duration of a day in seconds
    uint256 perDay = 1 days;
    // Timestamp of the last reward distribution
    uint256 public lastRewardTimestamp;
    // Amount of reward tokens per token staked
    uint256 accRewardPerToken;

    // Struct representing a staked NFT
    struct Stake {
        uint256 stackingTime; // Timestamp when the NFT was staked
        address originalOwner; // Address of the original owner of the NFT
    }

    // Struct representing a user
    struct User {
        uint256 totalBalance; // Total balance of staked NFTs
        uint256 debt; // Accumulated debt for rewards
    }

    // Custom errors
    error IncorrectOwner();

    constructor(address _nft) {
        nft = _nft;
        rewardToken = new RewardToken();
    }

    // Mapping of NFT token IDs to their corresponding stakes
    mapping(uint256 => Stake) public stakes;

    // Mapping of user addresses to their corresponding data
    mapping(address => User) public users;

    // Deposit NFT into a contract for the purpose of staking
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata)
        public
        override
        returns (bytes4 selector)
    {
        // Ensure that the sender is the NFT contract
        if (msg.sender != address(nft)) {
            revert();
        }

        // Update the reward
        UpdateReward();

        // Mint rewards to the user
        if (users[from].totalBalance > 0) {
            uint256 rewardToMint = users[from].totalBalance * accRewardPerToken - users[from].debt;
            RewardToken(rewardToken).mint(from, rewardToMint);
        }

        // Update user data
        users[from] = User({totalBalance: users[from].totalBalance + 1, debt: users[from].debt + accRewardPerToken});

        // Record the stake
        stakes[tokenId] = Stake({stackingTime: block.timestamp, originalOwner: from});

        return IERC721Receiver.onERC721Received.selector; // returns 0x150b7a02
    }

    // Users can withdraw NFT at any time
    function withdraw(uint256 tokenId) external {
        // Ensure that the sender is the original owner of the NFT
        if (msg.sender != stakes[tokenId].originalOwner) {
            revert IncorrectOwner();
        }

        // Update the reward
        UpdateReward();

        uint256 rewardToMint = users[msg.sender].totalBalance * accRewardPerToken - users[msg.sender].debt;
        RewardToken(rewardToken).mint(msg.sender, rewardToMint);

        // Update user data
        users[msg.sender] = User({totalBalance: users[msg.sender].totalBalance - 1, debt: users[msg.sender].debt});

        delete stakes[tokenId];

        // Transfer the NFT back to the original owner
        ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // Update the reward distribution
    function UpdateReward() internal {
        // Check if it's time to distribute rewards
        if (block.timestamp > lastRewardTimestamp) {
            uint256 stakedNFTSupply = ERC721(nft).balanceOf(address(this));

            // Ensure there are staked NFTs
            if (lastRewardTimestamp != 0) {
                uint256 timeSinceLastReward = block.timestamp - lastRewardTimestamp;

                // Calculate the reward per token accumulated during the staking period
                uint256 rewardPerTokenAccumulated = (rewardPer24Hours * timeSinceLastReward) / perDay;

                // Update the accumulated reward per token
                accRewardPerToken += rewardPerTokenAccumulated;
            }
            // Update the timestamp of the last reward distribution
            lastRewardTimestamp = block.timestamp;
        }
    }
}
